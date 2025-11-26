/**
 * Provider-agnostic VoIP interface
 * Allows switching between Voximplant, Twilio, and Telnyx
 */

export enum VoipProviderType {
  VOXIMPLANT = 'voximplant',
  TWILIO = 'twilio',
  TELNYX = 'telnyx',
}

export interface VoipCallOptions {
  to: string;
  from?: string;
  userId: string;
  webhookUrl?: string;
  clientState?: string;
  timeoutSecs?: number;
}

export interface VoipCallResult {
  callId: string;
  sessionId?: string;
  legId?: string;
  status: string;
  provider: VoipProviderType;
}

export interface VoipTokenResult {
  token: string;
  expiresIn: number;
  provider: VoipProviderType;
  // Provider-specific data for client SDK initialization
  providerConfig?: {
    // Voximplant
    accountName?: string;
    applicationName?: string;
    // Twilio
    identity?: string;
    // Telnyx
    appId?: string;
  };
}

export interface VoipWebhookPayload {
  provider: VoipProviderType;
  eventType: string;
  callId: string;
  sessionId?: string;
  legId?: string;
  from: string;
  to: string;
  status: string;
  direction: 'inbound' | 'outbound';
  startTime?: Date;
  answerTime?: Date;
  endTime?: Date;
  durationSeconds?: number;
  hangupCause?: string;
  recordingUrl?: string;
  rawPayload: any;
}

export interface VoipProviderHealth {
  provider: VoipProviderType;
  isHealthy: boolean;
  latencyMs?: number;
  lastChecked: Date;
  error?: string;
}

export interface IVoipProvider {
  readonly providerType: VoipProviderType;

  /**
   * Check if the provider is configured and ready
   */
  isConfigured(): boolean;

  /**
   * Health check for the provider
   */
  healthCheck(): Promise<VoipProviderHealth>;

  /**
   * Generate authentication token for client SDK
   */
  generateToken(userId: string, expiresIn?: number): Promise<VoipTokenResult>;

  /**
   * Initiate an outbound call
   */
  initiateCall(options: VoipCallOptions): Promise<VoipCallResult>;

  /**
   * Answer an incoming call
   */
  answerCall(callId: string, clientState?: string): Promise<void>;

  /**
   * Hangup a call
   */
  hangupCall(callId: string): Promise<void>;

  /**
   * Hold a call
   */
  holdCall?(callId: string): Promise<void>;

  /**
   * Resume a held call
   */
  resumeCall?(callId: string): Promise<void>;

  /**
   * Transfer call to another number
   */
  transferCall?(callId: string, toNumber: string): Promise<void>;

  /**
   * Start call recording
   */
  startRecording?(callId: string): Promise<void>;

  /**
   * Stop call recording
   */
  stopRecording?(callId: string): Promise<void>;

  /**
   * Send DTMF tones
   */
  sendDtmf?(callId: string, digits: string): Promise<void>;

  /**
   * Parse and normalize webhook payload
   */
  parseWebhook(payload: any, headers?: Record<string, string>): VoipWebhookPayload;

  /**
   * Verify webhook signature
   */
  verifyWebhookSignature(payload: string, signature: string, timestamp?: string): boolean;

  /**
   * Lookup phone number information
   */
  lookupPhoneNumber?(phoneNumber: string): Promise<{
    countryCode: string;
    carrier?: string;
    type?: string;
  }>;
}
