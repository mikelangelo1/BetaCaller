import { registerAs } from '@nestjs/config';

export default registerAs('voximplant', () => ({
  accountId: process.env.VOXIMPLANT_ACCOUNT_ID,
  accountName: process.env.VOXIMPLANT_ACCOUNT_NAME,
  apiKey: process.env.VOXIMPLANT_API_KEY,
  applicationId: process.env.VOXIMPLANT_APPLICATION_ID,
  applicationName: process.env.VOXIMPLANT_APPLICATION_NAME,
  ruleName: process.env.VOXIMPLANT_RULE_NAME,
  callerNumber: process.env.VOXIMPLANT_CALLER_NUMBER,
  webhookSecret: process.env.VOXIMPLANT_WEBHOOK_SECRET,
}));
