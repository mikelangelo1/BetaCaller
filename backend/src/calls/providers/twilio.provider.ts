import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as crypto from 'crypto';
import {
  IVoipProvider,
  VoipProviderType,
  VoipCallOptions,
  VoipCallResult,
  VoipTokenResult,
  VoipWebhookPayload,
  VoipProviderHealth,
} from './voip-provider.interface';

// Twilio SDK
import Twilio from 'twilio';
import { jwt } from 'twilio';

const { AccessToken } = jwt;
const { VoiceGrant } = AccessToken;

@Injectable()
export class TwilioProvider implements IVoipProvider {
  private readonly logger = new Logger(TwilioProvider.name);
  readonly providerType = VoipProviderType.TWILIO;

  private client: Twilio.Twilio | null = null;
  private accountSid: string;
  private authToken: string;
  private apiKeySid: string;
  private apiKeySecret: string;
  private twimlAppSid: string;
  private callerNumber: string;
  private webhookSecret: string;

  constructor(private configService: ConfigService) {
    this.accountSid = this.configService.get<string>('twilio.accountSid') || '';
    this.authToken = this.configService.get<string>('twilio.authToken') || '';
    this.apiKeySid = this.configService.get<string>('twilio.apiKeySid') || '';
    this.apiKeySecret = this.configService.get<string>('twilio.apiKeySecret') || '';
    this.twimlAppSid = this.configService.get<string>('twilio.twimlAppSid') || '';
    this.callerNumber = this.configService.get<string>('twilio.callerNumber') || '';
    this.webhookSecret = this.configService.get<string>('twilio.webhookSecret') || '';

    if (this.isConfigured()) {
      this.client = Twilio(this.accountSid, this.authToken);
      this.logger.log('Twilio provider initialized');
    } else {
      this.logger.warn('Twilio provider not fully configured');
    }
  }

  isConfigured(): boolean {
    return !!(this.accountSid && this.authToken && this.apiKeySid && this.apiKeySecret);
  }

  async healthCheck(): Promise<VoipProviderHealth> {
    const startTime = Date.now();
    try {
      if (!this.isConfigured() || !this.client) {
        return {
          provider: this.providerType,
          isHealthy: false,
          lastChecked: new Date(),
          error: 'Provider not configured',
        };
      }

      // Fetch account info to verify credentials
      const account = await this.client.api.accounts(this.accountSid).fetch();

      return {
        provider: this.providerType,
        isHealthy: account.status === 'active',
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
      // Create an access token for Twilio Voice SDK
      const accessToken = new AccessToken(
        this.accountSid,
        this.apiKeySid,
        this.apiKeySecret,
        {
          identity: userId,
          ttl: expiresIn,
        }
      );

      // Create a Voice grant for this token
      const voiceGrant = new VoiceGrant({
        outgoingApplicationSid: this.twimlAppSid,
        incomingAllow: true,
      });

      accessToken.addGrant(voiceGrant);

      const token = accessToken.toJwt();

      this.logger.log(`Generated Twilio token for user: ${userId}`);

      return {
        token,
        expiresIn,
        provider: this.providerType,
        providerConfig: {
          identity: userId,
        },
      };
    } catch (error: any) {
      this.logger.error('Error generating Twilio token:', error);
      throw error;
    }
  }

  async initiateCall(options: VoipCallOptions): Promise<VoipCallResult> {
    try {
      if (!this.client) {
        throw new Error('Twilio client not initialized');
      }

      const { to, from, userId, webhookUrl } = options;

      this.logger.log(`Initiating Twilio call from ${from || this.callerNumber} to ${to}`);

      const call = await this.client.calls.create({
        to,
        from: from || this.callerNumber,
        url: webhookUrl || `${process.env.BACKEND_URL}/calls/twilio/twiml`,
        statusCallback: `${process.env.BACKEND_URL}/calls/webhook/twilio`,
        statusCallbackEvent: ['initiated', 'ringing', 'answered', 'completed'],
        statusCallbackMethod: 'POST',
      });

      this.logger.log(`Twilio call initiated: ${call.sid}`);

      return {
        callId: call.sid,
        sessionId: call.sid,
        status: call.status,
        provider: this.providerType,
      };
    } catch (error: any) {
      this.logger.error('Error initiating Twilio call:', error);
      throw error;
    }
  }

  async answerCall(callId: string, clientState?: string): Promise<void> {
    try {
      if (!this.client) {
        throw new Error('Twilio client not initialized');
      }

      this.logger.log(`Answering Twilio call: ${callId}`);

      await this.client.calls(callId).update({
        status: 'in-progress',
      });
    } catch (error: any) {
      this.logger.error('Error answering Twilio call:', error);
      throw error;
    }
  }

  async hangupCall(callId: string): Promise<void> {
    try {
      if (!this.client) {
        throw new Error('Twilio client not initialized');
      }

      this.logger.log(`Hanging up Twilio call: ${callId}`);

      await this.client.calls(callId).update({
        status: 'completed',
      });
    } catch (error: any) {
      this.logger.error('Error hanging up Twilio call:', error);
      throw error;
    }
  }

  async holdCall(callId: string): Promise<void> {
    try {
      if (!this.client) {
        throw new Error('Twilio client not initialized');
      }

      this.logger.log(`Holding Twilio call: ${callId}`);

      // In Twilio, hold is typically done via TwiML or conference
      await this.client.calls(callId).update({
        twiml: '<Response><Play loop="0">http://com.twilio.sounds.music.s3.amazonaws.com/hold-music.mp3</Play></Response>',
      });
    } catch (error: any) {
      this.logger.error('Error holding Twilio call:', error);
      throw error;
    }
  }

  async resumeCall(callId: string): Promise<void> {
    this.logger.log(`Resuming Twilio call: ${callId}`);
    // Resume by redirecting back to the original TwiML
  }

  async transferCall(callId: string, toNumber: string): Promise<void> {
    try {
      if (!this.client) {
        throw new Error('Twilio client not initialized');
      }

      this.logger.log(`Transferring Twilio call ${callId} to ${toNumber}`);

      await this.client.calls(callId).update({
        twiml: `<Response><Dial>${toNumber}</Dial></Response>`,
      });
    } catch (error: any) {
      this.logger.error('Error transferring Twilio call:', error);
      throw error;
    }
  }

  async startRecording(callId: string): Promise<void> {
    try {
      if (!this.client) {
        throw new Error('Twilio client not initialized');
      }

      this.logger.log(`Starting recording for Twilio call: ${callId}`);

      await this.client.calls(callId).recordings.create();
    } catch (error: any) {
      this.logger.error('Error starting Twilio recording:', error);
      throw error;
    }
  }

  async stopRecording(callId: string): Promise<void> {
    try {
      if (!this.client) {
        throw new Error('Twilio client not initialized');
      }

      this.logger.log(`Stopping recording for Twilio call: ${callId}`);

      const recordings = await this.client.calls(callId).recordings.list({ limit: 1 });
      if (recordings.length > 0) {
        await this.client.calls(callId).recordings(recordings[0].sid).update({
          status: 'stopped',
        });
      }
    } catch (error: any) {
      this.logger.error('Error stopping Twilio recording:', error);
      throw error;
    }
  }

  async sendDtmf(callId: string, digits: string): Promise<void> {
    try {
      if (!this.client) {
        throw new Error('Twilio client not initialized');
      }

      this.logger.log(`Sending DTMF ${digits} to Twilio call: ${callId}`);

      await this.client.calls(callId).update({
        twiml: `<Response><Play digits="${digits}"/></Response>`,
      });
    } catch (error: any) {
      this.logger.error('Error sending DTMF:', error);
      throw error;
    }
  }

  parseWebhook(payload: any, headers?: Record<string, string>): VoipWebhookPayload {
    // Twilio webhook format
    return {
      provider: this.providerType,
      eventType: payload.CallStatus || payload.StatusCallbackEvent || 'unknown',
      callId: payload.CallSid || '',
      sessionId: payload.CallSid,
      from: payload.From || payload.Caller || '',
      to: payload.To || payload.Called || '',
      status: this.mapTwilioStatus(payload.CallStatus),
      direction: payload.Direction === 'inbound' ? 'inbound' : 'outbound',
      startTime: payload.Timestamp ? new Date(payload.Timestamp) : undefined,
      answerTime: payload.CallStatus === 'in-progress' ? new Date() : undefined,
      endTime: payload.CallStatus === 'completed' ? new Date() : undefined,
      durationSeconds: payload.CallDuration ? parseInt(payload.CallDuration) : undefined,
      hangupCause: payload.SipResponseCode,
      recordingUrl: payload.RecordingUrl,
      rawPayload: payload,
    };
  }

  verifyWebhookSignature(payload: string, signature: string, timestamp?: string): boolean {
    try {
      // Twilio uses X-Twilio-Signature header
      const { validateRequest } = require('twilio');

      // For Twilio, we need the full URL and POST parameters
      // This is a simplified check - in production, pass the full URL
      return validateRequest(
        this.authToken,
        signature,
        process.env.BACKEND_URL + '/calls/webhook/twilio',
        JSON.parse(payload)
      );
    } catch (error) {
      this.logger.error('Error verifying Twilio webhook signature:', error);
      return false;
    }
  }

  async lookupPhoneNumber(phoneNumber: string): Promise<{
    countryCode: string;
    carrier?: string;
    type?: string;
  }> {
    try {
      if (!this.client) {
        throw new Error('Twilio client not initialized');
      }

      const lookup = await this.client.lookups.v2.phoneNumbers(phoneNumber).fetch({
        fields: 'line_type_intelligence,caller_name',
      });

      return {
        countryCode: lookup.countryCode || '',
        carrier: lookup.callerName?.caller_name,
        type: lookup.lineTypeIntelligence?.type,
      };
    } catch (error: any) {
      this.logger.error('Error looking up phone number:', error);
      throw error;
    }
  }

  private mapTwilioStatus(status: string): string {
    const statusMap: Record<string, string> = {
      'queued': 'initiated',
      'ringing': 'ringing',
      'in-progress': 'answered',
      'completed': 'completed',
      'busy': 'busy',
      'failed': 'failed',
      'no-answer': 'no_answer',
      'canceled': 'canceled',
    };
    return statusMap[status] || status;
  }
}
