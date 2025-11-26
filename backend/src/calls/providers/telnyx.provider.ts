import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as crypto from 'crypto';
import Telnyx from 'telnyx';
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
export class TelnyxProvider implements IVoipProvider {
  private readonly logger = new Logger(TelnyxProvider.name);
  readonly providerType = VoipProviderType.TELNYX;

  private telnyx: any;
  private apiKey: string;
  private publicKey: string;
  private appId: string;
  private connectionId: string;
  private phoneNumber: string;
  private webhookSecret: string;

  constructor(private configService: ConfigService) {
    this.apiKey = this.configService.get<string>('telnyx.apiKey') || '';
    this.publicKey = this.configService.get<string>('telnyx.publicKey') || '';
    this.appId = this.configService.get<string>('telnyx.appId') || '';
    this.connectionId = this.configService.get<string>('telnyx.connectionId') || '';
    this.phoneNumber = this.configService.get<string>('telnyx.phoneNumber') || '';
    this.webhookSecret = this.configService.get<string>('telnyx.webhookSecret') || '';

    if (this.isConfigured()) {
      this.telnyx = new Telnyx({ apiKey: this.apiKey });
      this.logger.log('Telnyx provider initialized');
    } else {
      this.logger.warn('Telnyx provider not fully configured');
    }
  }

  isConfigured(): boolean {
    return !!(this.apiKey && this.connectionId);
  }

  async healthCheck(): Promise<VoipProviderHealth> {
    const startTime = Date.now();
    try {
      if (!this.isConfigured() || !this.telnyx) {
        return {
          provider: this.providerType,
          isHealthy: false,
          lastChecked: new Date(),
          error: 'Provider not configured',
        };
      }

      // Check balance to verify API connectivity
      const response = await this.telnyx.balance.retrieve();

      return {
        provider: this.providerType,
        isHealthy: response.data !== undefined,
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
      const jwt = require('jsonwebtoken');

      const tokenPayload = {
        user_id: userId,
        app_id: this.appId,
        expires_at: Math.floor(Date.now() / 1000) + expiresIn,
      };

      const token = jwt.sign(tokenPayload, this.apiKey, {
        algorithm: 'HS256',
        expiresIn: expiresIn,
      });

      this.logger.log(`Generated Telnyx token for user: ${userId}`);

      return {
        token,
        expiresIn,
        provider: this.providerType,
        providerConfig: {
          appId: this.appId,
        },
      };
    } catch (error: any) {
      this.logger.error('Error generating Telnyx token:', error);
      throw error;
    }
  }

  async initiateCall(options: VoipCallOptions): Promise<VoipCallResult> {
    try {
      if (!this.telnyx) {
        throw new Error('Telnyx client not initialized');
      }

      const { to, from, userId, webhookUrl, clientState, timeoutSecs } = options;

      this.logger.log(`Initiating Telnyx call from ${from || this.phoneNumber} to ${to}`);

      const call = await this.telnyx.calls.create({
        to,
        from: from || this.phoneNumber,
        connection_id: this.connectionId,
        webhook_url: webhookUrl,
        client_state: clientState ? Buffer.from(clientState).toString('base64') : undefined,
        timeout_secs: timeoutSecs || 30,
      });

      this.logger.log(`Telnyx call initiated: ${call.data.call_control_id}`);

      return {
        callId: call.data.call_control_id,
        sessionId: call.data.call_session_id,
        legId: call.data.call_leg_id,
        status: 'initiated',
        provider: this.providerType,
      };
    } catch (error: any) {
      this.logger.error('Error initiating Telnyx call:', error);
      throw error;
    }
  }

  async answerCall(callId: string, clientState?: string): Promise<void> {
    try {
      if (!this.telnyx) {
        throw new Error('Telnyx client not initialized');
      }

      this.logger.log(`Answering Telnyx call: ${callId}`);

      await this.telnyx.calls.answer(callId, {
        client_state: clientState ? Buffer.from(clientState).toString('base64') : undefined,
      });
    } catch (error: any) {
      this.logger.error('Error answering Telnyx call:', error);
      throw error;
    }
  }

  async hangupCall(callId: string): Promise<void> {
    try {
      if (!this.telnyx) {
        throw new Error('Telnyx client not initialized');
      }

      this.logger.log(`Hanging up Telnyx call: ${callId}`);

      await this.telnyx.calls.hangup(callId);
    } catch (error: any) {
      this.logger.error('Error hanging up Telnyx call:', error);
      throw error;
    }
  }

  async holdCall(callId: string): Promise<void> {
    try {
      if (!this.telnyx) {
        throw new Error('Telnyx client not initialized');
      }

      this.logger.log(`Holding Telnyx call: ${callId}`);

      await this.telnyx.calls.hold(callId);
    } catch (error: any) {
      this.logger.error('Error holding Telnyx call:', error);
      throw error;
    }
  }

  async resumeCall(callId: string): Promise<void> {
    try {
      if (!this.telnyx) {
        throw new Error('Telnyx client not initialized');
      }

      this.logger.log(`Resuming Telnyx call: ${callId}`);

      await this.telnyx.calls.unhold(callId);
    } catch (error: any) {
      this.logger.error('Error resuming Telnyx call:', error);
      throw error;
    }
  }

  async transferCall(callId: string, toNumber: string): Promise<void> {
    try {
      if (!this.telnyx) {
        throw new Error('Telnyx client not initialized');
      }

      this.logger.log(`Transferring Telnyx call ${callId} to ${toNumber}`);

      await this.telnyx.calls.transfer(callId, { to: toNumber });
    } catch (error: any) {
      this.logger.error('Error transferring Telnyx call:', error);
      throw error;
    }
  }

  async startRecording(callId: string): Promise<void> {
    try {
      if (!this.telnyx) {
        throw new Error('Telnyx client not initialized');
      }

      this.logger.log(`Starting recording for Telnyx call: ${callId}`);

      await this.telnyx.calls.recordStart(callId, {
        format: 'mp3',
        channels: 'single',
      });
    } catch (error: any) {
      this.logger.error('Error starting Telnyx recording:', error);
      throw error;
    }
  }

  async stopRecording(callId: string): Promise<void> {
    try {
      if (!this.telnyx) {
        throw new Error('Telnyx client not initialized');
      }

      this.logger.log(`Stopping recording for Telnyx call: ${callId}`);

      await this.telnyx.calls.recordStop(callId);
    } catch (error: any) {
      this.logger.error('Error stopping Telnyx recording:', error);
      throw error;
    }
  }

  async sendDtmf(callId: string, digits: string): Promise<void> {
    try {
      if (!this.telnyx) {
        throw new Error('Telnyx client not initialized');
      }

      this.logger.log(`Sending DTMF ${digits} to Telnyx call: ${callId}`);

      await this.telnyx.calls.sendDTMF(callId, { digits });
    } catch (error: any) {
      this.logger.error('Error sending DTMF:', error);
      throw error;
    }
  }

  parseWebhook(payload: any, headers?: Record<string, string>): VoipWebhookPayload {
    const eventPayload = payload.payload || payload;

    return {
      provider: this.providerType,
      eventType: payload.event_type || 'unknown',
      callId: eventPayload.call_control_id || '',
      sessionId: eventPayload.call_session_id,
      legId: eventPayload.call_leg_id,
      from: eventPayload.from || '',
      to: eventPayload.to || '',
      status: this.mapTelnyxStatus(payload.event_type),
      direction: eventPayload.direction === 'incoming' ? 'inbound' : 'outbound',
      startTime: eventPayload.start_time ? new Date(eventPayload.start_time) : undefined,
      answerTime: eventPayload.answer_time ? new Date(eventPayload.answer_time) : undefined,
      endTime: eventPayload.end_time ? new Date(eventPayload.end_time) : undefined,
      durationSeconds: eventPayload.duration_secs,
      hangupCause: eventPayload.hangup_cause,
      recordingUrl: eventPayload.recording_url,
      rawPayload: payload,
    };
  }

  verifyWebhookSignature(payload: string, signature: string, timestamp?: string): boolean {
    if (!this.webhookSecret) {
      this.logger.warn('Telnyx webhook secret not configured');
      return false;
    }

    try {
      const expectedSignature = crypto
        .createHmac('sha256', this.webhookSecret)
        .update(`${timestamp}|${payload}`)
        .digest('hex');

      return crypto.timingSafeEqual(
        Buffer.from(signature),
        Buffer.from(expectedSignature)
      );
    } catch (error) {
      this.logger.error('Error verifying Telnyx webhook signature:', error);
      return false;
    }
  }

  async lookupPhoneNumber(phoneNumber: string): Promise<{
    countryCode: string;
    carrier?: string;
    type?: string;
  }> {
    try {
      if (!this.telnyx) {
        throw new Error('Telnyx client not initialized');
      }

      const response = await this.telnyx.numberLookup.retrieve(phoneNumber);

      return {
        countryCode: response.data.country_code || '',
        carrier: response.data.carrier?.name,
        type: response.data.type,
      };
    } catch (error: any) {
      this.logger.error('Error looking up phone number:', error);
      throw error;
    }
  }

  private mapTelnyxStatus(eventType: string): string {
    const statusMap: Record<string, string> = {
      'call.initiated': 'initiated',
      'call.ringing': 'ringing',
      'call.answered': 'answered',
      'call.hangup': 'completed',
      'call.machine.detection.ended': 'answered',
    };
    return statusMap[eventType] || eventType;
  }
}
