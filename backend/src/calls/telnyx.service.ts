import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Telnyx from 'telnyx';

export interface TelnyxCallOptions {
  to: string;
  from: string;
  connectionId: string;
  webhookUrl?: string;
  answerUrl?: string;
  clientState?: string;
  timeoutSecs?: number;
}

export interface TelnyxTokenOptions {
  userId: string;
  expiresIn?: number; // seconds
}

@Injectable()
export class TelnyxService {
  private readonly logger = new Logger(TelnyxService.name);
  private telnyx: any;
  private apiKey: string;
  private publicKey: string;
  private appId: string;
  private connectionId: string;
  private phoneNumber: string;

  constructor(private configService: ConfigService) {
    this.apiKey = this.configService.get<string>('telnyx.apiKey');
    this.publicKey = this.configService.get<string>('telnyx.publicKey');
    this.appId = this.configService.get<string>('telnyx.appId');
    this.connectionId = this.configService.get<string>('telnyx.connectionId');
    this.phoneNumber = this.configService.get<string>('telnyx.phoneNumber');

    if (this.apiKey) {
      this.telnyx = new Telnyx({
        apiKey: this.apiKey,
      });
      this.logger.log('Telnyx service initialized');
    } else {
      this.logger.warn('Telnyx API key not configured');
    }
  }

  /**
   * Generate a Telnyx RTC token for WebRTC calling
   */
  async generateRTCToken(options: TelnyxTokenOptions): Promise<string> {
    try {
      const { userId, expiresIn = 86400 } = options; // 24 hours default

      // For Telnyx, we use JWT tokens for WebRTC
      // The token contains user info and permissions
      const tokenPayload = {
        user_id: userId,
        app_id: this.appId,
        expires_at: Math.floor(Date.now() / 1000) + expiresIn,
      };

      // Note: In production, you should use proper JWT signing
      // with your Telnyx API key as the secret
      const jwt = require('jsonwebtoken');
      const token = jwt.sign(tokenPayload, this.apiKey, {
        algorithm: 'HS256',
        expiresIn: expiresIn,
      });

      this.logger.log(`Generated RTC token for user: ${userId}`);
      return token;
    } catch (error) {
      this.logger.error('Error generating RTC token:', error);
      throw error;
    }
  }

  /**
   * Initiate an outbound call using Telnyx Call Control API
   */
  async initiateCall(options: TelnyxCallOptions) {
    try {
      const {
        to,
        from = this.phoneNumber,
        connectionId = this.connectionId,
        webhookUrl,
        clientState,
        timeoutSecs = 30,
      } = options;

      this.logger.log(`Initiating call from ${from} to ${to}`);

      const call = await this.telnyx.calls.create({
        to,
        from,
        connection_id: connectionId,
        webhook_url: webhookUrl,
        client_state: clientState ? Buffer.from(clientState).toString('base64') : undefined,
        timeout_secs: timeoutSecs,
      });

      this.logger.log(`Call initiated: ${call.data.call_control_id}`);
      return call.data;
    } catch (error) {
      this.logger.error('Error initiating call:', error);
      throw error;
    }
  }

  /**
   * Answer an incoming call
   */
  async answerCall(callControlId: string, clientState?: string) {
    try {
      this.logger.log(`Answering call: ${callControlId}`);

      const response = await this.telnyx.calls.answer(callControlId, {
        client_state: clientState ? Buffer.from(clientState).toString('base64') : undefined,
      });

      return response.data;
    } catch (error) {
      this.logger.error('Error answering call:', error);
      throw error;
    }
  }

  /**
   * Hangup a call
   */
  async hangupCall(callControlId: string) {
    try {
      this.logger.log(`Hanging up call: ${callControlId}`);

      const response = await this.telnyx.calls.hangup(callControlId);
      return response.data;
    } catch (error) {
      this.logger.error('Error hanging up call:', error);
      throw error;
    }
  }

  /**
   * Bridge two calls together
   */
  async bridgeCalls(callControlId: string, targetCallControlId: string) {
    try {
      this.logger.log(`Bridging calls: ${callControlId} -> ${targetCallControlId}`);

      const response = await this.telnyx.calls.bridge(callControlId, {
        call_control_id: targetCallControlId,
      });

      return response.data;
    } catch (error) {
      this.logger.error('Error bridging calls:', error);
      throw error;
    }
  }

  /**
   * Start call recording
   */
  async startRecording(callControlId: string, options?: {
    format?: 'wav' | 'mp3';
    channels?: 'single' | 'dual';
  }) {
    try {
      this.logger.log(`Starting recording for call: ${callControlId}`);

      const response = await this.telnyx.calls.recordStart(callControlId, {
        format: options?.format || 'mp3',
        channels: options?.channels || 'single',
      });

      return response.data;
    } catch (error) {
      this.logger.error('Error starting recording:', error);
      throw error;
    }
  }

  /**
   * Stop call recording
   */
  async stopRecording(callControlId: string) {
    try {
      this.logger.log(`Stopping recording for call: ${callControlId}`);

      const response = await this.telnyx.calls.recordStop(callControlId);
      return response.data;
    } catch (error) {
      this.logger.error('Error stopping recording:', error);
      throw error;
    }
  }

  /**
   * Play audio to caller
   */
  async playAudio(callControlId: string, audioUrl: string) {
    try {
      this.logger.log(`Playing audio on call: ${callControlId}`);

      const response = await this.telnyx.calls.playback_start(callControlId, {
        audio_url: audioUrl,
      });

      return response.data;
    } catch (error) {
      this.logger.error('Error playing audio:', error);
      throw error;
    }
  }

  /**
   * Speak text to caller (TTS)
   */
  async speak(callControlId: string, text: string, options?: {
    voice?: string;
    language?: string;
  }) {
    try {
      this.logger.log(`Speaking on call: ${callControlId}`);

      const response = await this.telnyx.calls.speak(callControlId, {
        payload: text,
        voice: options?.voice || 'female',
        language: options?.language || 'en-US',
      });

      return response.data;
    } catch (error) {
      this.logger.error('Error speaking:', error);
      throw error;
    }
  }

  /**
   * Transfer call to another number
   */
  async transferCall(callControlId: string, toNumber: string) {
    try {
      this.logger.log(`Transferring call ${callControlId} to ${toNumber}`);

      const response = await this.telnyx.calls.transfer(callControlId, {
        to: toNumber,
      });

      return response.data;
    } catch (error) {
      this.logger.error('Error transferring call:', error);
      throw error;
    }
  }

  /**
   * Get call information
   */
  async getCallInfo(callControlId: string) {
    try {
      const response = await this.telnyx.calls.retrieve(callControlId);
      return response.data;
    } catch (error) {
      this.logger.error('Error getting call info:', error);
      throw error;
    }
  }

  /**
   * Verify webhook signature
   */
  verifyWebhookSignature(payload: string, signature: string, timestamp: string): boolean {
    try {
      const webhookSecret = this.configService.get<string>('telnyx.webhookSecret');
      if (!webhookSecret) {
        this.logger.warn('Webhook secret not configured');
        return false;
      }

      const crypto = require('crypto');
      const expectedSignature = crypto
        .createHmac('sha256', webhookSecret)
        .update(`${timestamp}|${payload}`)
        .digest('hex');

      return crypto.timingSafeEqual(
        Buffer.from(signature),
        Buffer.from(expectedSignature),
      );
    } catch (error) {
      this.logger.error('Error verifying webhook signature:', error);
      return false;
    }
  }

  /**
   * Lookup phone number information (carrier, country, etc.)
   */
  async lookupPhoneNumber(phoneNumber: string) {
    try {
      // Telnyx number lookup API
      const response = await this.telnyx.numberLookup.retrieve(phoneNumber);
      return response.data;
    } catch (error) {
      this.logger.error('Error looking up phone number:', error);
      throw error;
    }
  }

  /**
   * Get available phone numbers for purchase
   */
  async searchAvailableNumbers(options: {
    countryCode?: string;
    features?: string[];
    limit?: number;
  }) {
    try {
      const response = await this.telnyx.availablePhoneNumbers.list({
        filter: {
          country_code: options.countryCode || 'NG',
          features: options.features || ['voice', 'sms'],
          limit: options.limit || 10,
        },
      });

      return response.data;
    } catch (error) {
      this.logger.error('Error searching available numbers:', error);
      throw error;
    }
  }

  /**
   * Get current Telnyx balance
   */
  async getBalance() {
    try {
      const response = await this.telnyx.balance.retrieve();
      return response.data;
    } catch (error) {
      this.logger.error('Error getting balance:', error);
      throw error;
    }
  }
}
