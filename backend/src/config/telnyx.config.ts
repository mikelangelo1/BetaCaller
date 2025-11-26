import { registerAs } from '@nestjs/config';

export default registerAs('telnyx', () => ({
  apiKey: process.env.TELNYX_API_KEY,
  publicKey: process.env.TELNYX_PUBLIC_KEY,
  appId: process.env.TELNYX_APP_ID,
  connectionId: process.env.TELNYX_CONNECTION_ID,
  phoneNumber: process.env.TELNYX_PHONE_NUMBER,
  webhookSecret: process.env.TELNYX_WEBHOOK_SECRET,
}));
