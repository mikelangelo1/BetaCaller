import twilio from 'twilio';
import logger from '../utils/logger';

const AccessToken = twilio.jwt.AccessToken;
const VoiceGrant = AccessToken.VoiceGrant;

export class TwilioService {
  private accountSid: string;
  private authToken: string;
  private apiKey: string;
  private apiSecret: string;
  private twimlAppSid: string;
  private phoneNumber: string;
  private client: twilio.Twilio;

  constructor() {
    this.accountSid = process.env.TWILIO_ACCOUNT_SID || '';
    this.authToken = process.env.TWILIO_AUTH_TOKEN || '';
    this.apiKey = process.env.TWILIO_API_KEY || '';
    this.apiSecret = process.env.TWILIO_API_SECRET || '';
    this.twimlAppSid = process.env.TWILIO_TWIML_APP_SID || '';
    this.phoneNumber = process.env.TWILIO_PHONE_NUMBER || '';

    if (!this.accountSid || !this.authToken) {
      logger.warn('Twilio credentials not configured');
    } else {
      this.client = twilio(this.accountSid, this.authToken);
    }
  }

  generateAccessToken(identity: string): string {
    if (!this.apiKey || !this.apiSecret) {
      throw new Error('Twilio API credentials not configured');
    }

    const voiceGrant = new VoiceGrant({
      outgoingApplicationSid: this.twimlAppSid,
      incomingAllow: true
    });

    const token = new AccessToken(this.accountSid, this.apiKey, this.apiSecret, {
      identity,
      ttl: 3600 // 1 hour
    });

    token.addGrant(voiceGrant);

    logger.info(`Generated Twilio access token for identity: ${identity}`);

    return token.toJwt();
  }

  async getCallDetails(callSid: string) {
    try {
      const call = await this.client.calls(callSid).fetch();
      return {
        sid: call.sid,
        status: call.status,
        duration: call.duration,
        price: call.price,
        priceUnit: call.priceUnit,
        from: call.from,
        to: call.to,
        startTime: call.startTime,
        endTime: call.endTime
      };
    } catch (error) {
      logger.error('Error fetching call details:', error);
      throw error;
    }
  }

  async getCallRate(toNumber: string): Promise<number> {
    // Extract country code and get rate
    // For now, return default rate
    return parseFloat(process.env.DEFAULT_CALL_RATE || '0.012');
  }

  estimateCallCost(durationSeconds: number, ratePerMinute: number): number {
    const minutes = durationSeconds / 60;
    return parseFloat((minutes * ratePerMinute).toFixed(4));
  }
}

export default new TwilioService();
