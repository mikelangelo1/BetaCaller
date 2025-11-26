import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as crypto from 'crypto';
import axios from 'axios';
import {
  IVoipProvider,
  VoipProviderType,
  VoipCallOptions,
  VoipCallResult,
  VoipTokenResult,
  VoipWebhookPayload,
  VoipProviderHealth,
} from './voip-provider.interface';

@Injectable()
export class VoximplantProvider implements IVoipProvider {
  private readonly logger = new Logger(VoximplantProvider.name);
  readonly providerType = VoipProviderType.VOXIMPLANT;

  private accountId: string;
  private apiKey: string;
  private applicationId: string;
  private applicationName: string;
  private accountName: string;
  private ruleName: string;
  private callerNumber: string;
  private webhookSecret: string;

  private readonly apiBaseUrl = 'https://api.voximplant.com/platform_api';

  constructor(private configService: ConfigService) {
    this.accountId = this.configService.get<string>('voximplant.accountId') || '';
    this.apiKey = this.configService.get<string>('voximplant.apiKey') || '';
    this.applicationId = this.configService.get<string>('voximplant.applicationId') || '';
    this.applicationName = this.configService.get<string>('voximplant.applicationName') || '';
    this.accountName = this.configService.get<string>('voximplant.accountName') || '';
    this.ruleName = this.configService.get<string>('voximplant.ruleName') || '';
    this.callerNumber = this.configService.get<string>('voximplant.callerNumber') || '';
    this.webhookSecret = this.configService.get<string>('voximplant.webhookSecret') || '';

    if (this.isConfigured()) {
      this.logger.log('Voximplant provider initialized');
    } else {
      this.logger.warn('Voximplant provider not fully configured');
    }
  }

  isConfigured(): boolean {
    return !!(this.accountId && this.apiKey && this.applicationId);
  }

  async healthCheck(): Promise<VoipProviderHealth> {
    const startTime = Date.now();
    try {
      if (!this.isConfigured()) {
        return {
          provider: this.providerType,
          isHealthy: false,
          lastChecked: new Date(),
          error: 'Provider not configured',
        };
      }

      // Call Voximplant API to check account info
      const response = await this.makeApiCall('GetAccountInfo', {});

      return {
        provider: this.providerType,
        isHealthy: response.result !== undefined,
        latencyMs: Date.now() - startTime,
        lastChecked: new Date(),
      };
    } catch (error: any) {
      return {
        provider: this.providerType,
        isHealthy: false,
        latencyMs: Date.now() - startTime,
        lastChecked: new Date(),
        error: error.message,
      };
    }
  }

  async generateToken(userId: string, expiresIn: number = 86400): Promise<VoipTokenResult> {
    try {
      // For Voximplant, we create a one-time login key for the user
      // The client will use this with the Voximplant SDK
      const response = await this.makeApiCall('CreateKey', {
        application_id: this.applicationId,
        key_name: `user_${userId}_${Date.now()}`,
      });

      // Generate a JWT token for our backend authentication
      const jwt = require('jsonwebtoken');
      const token = jwt.sign(
        {
          userId,
          provider: this.providerType,
          accountName: this.accountName,
          applicationName: this.applicationName,
          exp: Math.floor(Date.now() / 1000) + expiresIn,
        },
        this.apiKey,
        { algorithm: 'HS256' }
      );

      this.logger.log(`Generated Voximplant token for user: ${userId}`);

      return {
        token,
        expiresIn,
        provider: this.providerType,
        providerConfig: {
          accountName: this.accountName,
          applicationName: this.applicationName,
        },
      };
    } catch (error: any) {
      this.logger.error('Error generating Voximplant token:', error);
      throw error;
    }
  }

  async initiateCall(options: VoipCallOptions): Promise<VoipCallResult> {
    try {
      const { to, from, userId, webhookUrl } = options;

      this.logger.log(`Initiating Voximplant call from ${from || this.callerNumber} to ${to}`);

      // Start a call scenario in Voximplant
      const response = await this.makeApiCall('StartScenarios', {
        rule_id: this.ruleName,
        user_id: userId,
        script_custom_data: JSON.stringify({
          to,
          from: from || this.callerNumber,
          webhookUrl,
          userId,
        }),
      });

      const callId = response.result?.media_session_access_url ||
                     response.result?.session_id ||
                     `vox_${Date.now()}`;

      this.logger.log(`Voximplant call initiated: ${callId}`);

      return {
        callId,
        sessionId: response.result?.session_id,
        status: 'initiated',
        provider: this.providerType,
      };
    } catch (error: any) {
      this.logger.error('Error initiating Voximplant call:', error);
      throw error;
    }
  }

  async answerCall(callId: string, clientState?: string): Promise<void> {
    // Voximplant handles this through the VoxEngine scenario
    this.logger.log(`Voximplant answer call: ${callId}`);
  }

  async hangupCall(callId: string): Promise<void> {
    try {
      this.logger.log(`Hanging up Voximplant call: ${callId}`);

      // In Voximplant, hangup is typically handled by the VoxEngine scenario
      // For server-initiated hangup, we can use the HTTP API
      await this.makeApiCall('StopMediaSession', {
        media_session_id: callId,
      });
    } catch (error: any) {
      this.logger.error('Error hanging up Voximplant call:', error);
      throw error;
    }
  }

  async holdCall(callId: string): Promise<void> {
    this.logger.log(`Hold call (handled by VoxEngine): ${callId}`);
  }

  async resumeCall(callId: string): Promise<void> {
    this.logger.log(`Resume call (handled by VoxEngine): ${callId}`);
  }

  async startRecording(callId: string): Promise<void> {
    this.logger.log(`Start recording (handled by VoxEngine): ${callId}`);
  }

  async stopRecording(callId: string): Promise<void> {
    this.logger.log(`Stop recording (handled by VoxEngine): ${callId}`);
  }

  parseWebhook(payload: any, headers?: Record<string, string>): VoipWebhookPayload {
    // Voximplant webhook format
    const eventType = payload.event || payload.type || 'unknown';

    return {
      provider: this.providerType,
      eventType,
      callId: payload.call_id || payload.session_id || '',
      sessionId: payload.session_id,
      from: payload.caller_id || payload.from || '',
      to: payload.destination || payload.to || '',
      status: this.mapVoximplantStatus(eventType),
      direction: payload.direction === 'incoming' ? 'inbound' : 'outbound',
      startTime: payload.start_time ? new Date(payload.start_time) : undefined,
      answerTime: payload.answer_time ? new Date(payload.answer_time) : undefined,
      endTime: payload.end_time ? new Date(payload.end_time) : undefined,
      durationSeconds: payload.duration,
      hangupCause: payload.hangup_reason,
      recordingUrl: payload.record_url,
      rawPayload: payload,
    };
  }

  verifyWebhookSignature(payload: string, signature: string, timestamp?: string): boolean {
    if (!this.webhookSecret) {
      this.logger.warn('Voximplant webhook secret not configured');
      return false;
    }

    try {
      const expectedSignature = crypto
        .createHmac('sha256', this.webhookSecret)
        .update(payload)
        .digest('hex');

      return crypto.timingSafeEqual(
        Buffer.from(signature),
        Buffer.from(expectedSignature)
      );
    } catch (error) {
      this.logger.error('Error verifying Voximplant webhook signature:', error);
      return false;
    }
  }

  private mapVoximplantStatus(eventType: string): string {
    const statusMap: Record<string, string> = {
      'call.started': 'initiated',
      'call.ringing': 'ringing',
      'call.connected': 'answered',
      'call.disconnected': 'completed',
      'call.failed': 'failed',
    };
    return statusMap[eventType] || eventType;
  }

  private async makeApiCall(method: string, params: Record<string, any>): Promise<any> {
    const url = `${this.apiBaseUrl}/${method}`;

    const response = await axios.post(url, null, {
      params: {
        account_id: this.accountId,
        api_key: this.apiKey,
        ...params,
      },
    });

    if (response.data.error) {
      throw new Error(response.data.error.msg || 'Voximplant API error');
    }

    return response.data;
  }
}
