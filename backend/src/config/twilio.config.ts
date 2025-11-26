import { registerAs } from '@nestjs/config';

export default registerAs('twilio', () => ({
  accountSid: process.env.TWILIO_ACCOUNT_SID,
  authToken: process.env.TWILIO_AUTH_TOKEN,
  apiKeySid: process.env.TWILIO_API_KEY_SID,
  apiKeySecret: process.env.TWILIO_API_KEY_SECRET,
  twimlAppSid: process.env.TWILIO_TWIML_APP_SID,
  callerNumber: process.env.TWILIO_CALLER_NUMBER,
  webhookSecret: process.env.TWILIO_WEBHOOK_SECRET,
}));
