import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Cron, CronExpression } from '@nestjs/schedule';
import {
  IVoipProvider,
  VoipProviderType,
  VoipProviderHealth,
  VoipCallOptions,
  VoipCallResult,
  VoipTokenResult,
  VoipWebhookPayload,
} from './voip-provider.interface';
import { VoximplantProvider } from './voximplant.provider';
import { TwilioProvider } from './twilio.provider';
import { TelnyxProvider } from './telnyx.provider';

interface ProviderStatus {
  provider: IVoipProvider;
  health: VoipProviderHealth;
  priority: number;
  failureCount: number;
  lastFailure?: Date;
}

@Injectable()
export class VoipProviderManager implements OnModuleInit {
  private readonly logger = new Logger(VoipProviderManager.name);

  private providers: Map<VoipProviderType, ProviderStatus> = new Map();
  private activeProvider: VoipProviderType;
  private readonly maxFailuresBeforeSwitch = 3;
  private readonly failureResetMinutes = 5;

  constructor(
    private configService: ConfigService,
    private voximplantProvider: VoximplantProvider,
    private twilioProvider: TwilioProvider,
    private telnyxProvider: TelnyxProvider,
  ) {
    // Default provider order (configurable via env)
    const defaultProvider = this.configService.get<string>('voip.defaultProvider') || 'voximplant';
    this.activeProvider = defaultProvider as VoipProviderType;
  }

  async onModuleInit() {
    // Initialize all providers with their priorities
    const providerPriorities = this.getProviderPriorities();

    this.registerProvider(this.voximplantProvider, providerPriorities.voximplant);
    this.registerProvider(this.twilioProvider, providerPriorities.twilio);
    this.registerProvider(this.telnyxProvider, providerPriorities.telnyx);

    // Run initial health check
    await this.checkAllProvidersHealth();

    // Set active provider to the healthiest one
    await this.selectBestProvider();

    this.logger.log(`VoIP Provider Manager initialized. Active provider: ${this.activeProvider}`);
  }

  private getProviderPriorities(): Record<string, number> {
    // Lower number = higher priority
    const defaultOrder = this.configService.get<string>('voip.providerOrder') || 'voximplant,twilio,telnyx';
    const order = defaultOrder.split(',').map(p => p.trim().toLowerCase());

    return {
      voximplant: order.indexOf('voximplant') !== -1 ? order.indexOf('voximplant') : 99,
      twilio: order.indexOf('twilio') !== -1 ? order.indexOf('twilio') : 99,
      telnyx: order.indexOf('telnyx') !== -1 ? order.indexOf('telnyx') : 99,
    };
  }

  private registerProvider(provider: IVoipProvider, priority: number) {
    this.providers.set(provider.providerType, {
      provider,
      health: {
        provider: provider.providerType,
        isHealthy: false,
        lastChecked: new Date(),
      },
      priority,
      failureCount: 0,
    });
  }

  /**
   * Get the currently active provider
   */
  getActiveProvider(): IVoipProvider {
    const status = this.providers.get(this.activeProvider);
    if (!status) {
      throw new Error('No active VoIP provider available');
    }
    return status.provider;
  }

  /**
   * Get provider by type
   */
  getProvider(type: VoipProviderType): IVoipProvider | undefined {
    return this.providers.get(type)?.provider;
  }

  /**
   * Get all provider statuses
   */
  getAllProviderStatuses(): ProviderStatus[] {
    return Array.from(this.providers.values());
  }

  /**
   * Get health status of all providers
   */
  async getHealthStatus(): Promise<Record<string, VoipProviderHealth>> {
    const health: Record<string, VoipProviderHealth> = {};

    for (const [type, status] of this.providers) {
      health[type] = status.health;
    }

    return health;
  }

  /**
   * Manually switch to a specific provider
   */
  async switchProvider(type: VoipProviderType): Promise<boolean> {
    const status = this.providers.get(type);
    if (!status) {
      this.logger.error(`Provider ${type} not registered`);
      return false;
    }

    if (!status.provider.isConfigured()) {
      this.logger.error(`Provider ${type} is not configured`);
      return false;
    }

    // Check health before switching
    const health = await status.provider.healthCheck();
    if (!health.isHealthy) {
      this.logger.warn(`Provider ${type} is not healthy: ${health.error}`);
      return false;
    }

    this.activeProvider = type;
    this.logger.log(`Switched to provider: ${type}`);
    return true;
  }

  /**
   * Health check all providers (runs every 30 seconds)
   */
  @Cron(CronExpression.EVERY_30_SECONDS)
  async checkAllProvidersHealth() {
    this.logger.debug('Running provider health checks...');

    for (const [type, status] of this.providers) {
      try {
        if (status.provider.isConfigured()) {
          const health = await status.provider.healthCheck();
          status.health = health;

          // Reset failure count if healthy
          if (health.isHealthy) {
            status.failureCount = 0;
            status.lastFailure = undefined;
          }
        }
      } catch (error: any) {
        this.logger.error(`Health check failed for ${type}: ${error.message}`);
        status.health = {
          provider: type,
          isHealthy: false,
          lastChecked: new Date(),
          error: error.message,
        };
      }
    }

    // Check if we need to switch providers
    const activeStatus = this.providers.get(this.activeProvider);
    if (activeStatus && !activeStatus.health.isHealthy) {
      this.logger.warn(`Active provider ${this.activeProvider} is unhealthy, selecting new provider...`);
      await this.selectBestProvider();
    }
  }

  /**
   * Select the best available provider based on health and priority
   */
  private async selectBestProvider(): Promise<void> {
    const healthyProviders = Array.from(this.providers.entries())
      .filter(([_, status]) => status.health.isHealthy && status.provider.isConfigured())
      .sort((a, b) => a[1].priority - b[1].priority);

    if (healthyProviders.length > 0) {
      const [bestType] = healthyProviders[0];
      if (bestType !== this.activeProvider) {
        this.logger.log(`Switching from ${this.activeProvider} to ${bestType}`);
        this.activeProvider = bestType;
      }
    } else {
      this.logger.error('No healthy VoIP providers available!');
    }
  }

  /**
   * Record a failure for the active provider
   */
  private async recordFailure(error: any): Promise<void> {
    const status = this.providers.get(this.activeProvider);
    if (!status) return;

    status.failureCount++;
    status.lastFailure = new Date();

    this.logger.warn(
      `Provider ${this.activeProvider} failure #${status.failureCount}: ${error.message}`
    );

    // Switch providers if too many failures
    if (status.failureCount >= this.maxFailuresBeforeSwitch) {
      this.logger.error(
        `Provider ${this.activeProvider} exceeded failure threshold, switching...`
      );
      status.health.isHealthy = false;
      await this.selectBestProvider();
    }
  }

  /**
   * Execute a call with automatic failover
   */
  async executeWithFailover<T>(
    operation: (provider: IVoipProvider) => Promise<T>,
    maxRetries: number = 2,
  ): Promise<T> {
    let lastError: any;
    const triedProviders = new Set<VoipProviderType>();

    for (let attempt = 0; attempt < maxRetries; attempt++) {
      const provider = this.getActiveProvider();
      triedProviders.add(provider.providerType);

      try {
        return await operation(provider);
      } catch (error: any) {
        lastError = error;
        this.logger.error(
          `Operation failed on ${provider.providerType} (attempt ${attempt + 1}): ${error.message}`
        );
        await this.recordFailure(error);

        // If we've tried all providers, throw
        if (triedProviders.size >= this.providers.size) {
          break;
        }
      }
    }

    throw lastError || new Error('All VoIP providers failed');
  }

  // ============ Proxy methods with failover ============

  async generateToken(userId: string, expiresIn?: number): Promise<VoipTokenResult> {
    return this.executeWithFailover(provider =>
      provider.generateToken(userId, expiresIn)
    );
  }

  async initiateCall(options: VoipCallOptions): Promise<VoipCallResult> {
    return this.executeWithFailover(provider =>
      provider.initiateCall(options)
    );
  }

  async answerCall(callId: string, clientState?: string): Promise<void> {
    const provider = this.getActiveProvider();
    return provider.answerCall(callId, clientState);
  }

  async hangupCall(callId: string): Promise<void> {
    const provider = this.getActiveProvider();
    return provider.hangupCall(callId);
  }

  async holdCall(callId: string): Promise<void> {
    const provider = this.getActiveProvider();
    if (provider.holdCall) {
      return provider.holdCall(callId);
    }
  }

  async resumeCall(callId: string): Promise<void> {
    const provider = this.getActiveProvider();
    if (provider.resumeCall) {
      return provider.resumeCall(callId);
    }
  }

  async startRecording(callId: string): Promise<void> {
    const provider = this.getActiveProvider();
    if (provider.startRecording) {
      return provider.startRecording(callId);
    }
  }

  async stopRecording(callId: string): Promise<void> {
    const provider = this.getActiveProvider();
    if (provider.stopRecording) {
      return provider.stopRecording(callId);
    }
  }

  /**
   * Parse webhook from any provider
   */
  parseWebhook(
    providerType: VoipProviderType,
    payload: any,
    headers?: Record<string, string>,
  ): VoipWebhookPayload {
    const provider = this.getProvider(providerType);
    if (!provider) {
      throw new Error(`Provider ${providerType} not found`);
    }
    return provider.parseWebhook(payload, headers);
  }

  /**
   * Verify webhook signature
   */
  verifyWebhookSignature(
    providerType: VoipProviderType,
    payload: string,
    signature: string,
    timestamp?: string,
  ): boolean {
    const provider = this.getProvider(providerType);
    if (!provider) {
      return false;
    }
    return provider.verifyWebhookSignature(payload, signature, timestamp);
  }
}
