import { registerAs } from '@nestjs/config';

export default registerAs('voip', () => ({
  // Default provider to use: 'voximplant', 'twilio', or 'telnyx'
  defaultProvider: process.env.VOIP_DEFAULT_PROVIDER || 'voximplant',

  // Provider priority order (comma-separated)
  // Lower priority = used first. Example: 'voximplant,twilio,telnyx'
  providerOrder: process.env.VOIP_PROVIDER_ORDER || 'voximplant,twilio,telnyx',

  // Maximum failures before switching to next provider
  maxFailuresBeforeSwitch: parseInt(process.env.VOIP_MAX_FAILURES || '3', 10),

  // Minutes before failure count resets
  failureResetMinutes: parseInt(process.env.VOIP_FAILURE_RESET_MINUTES || '5', 10),

  // Enable automatic failover
  autoFailover: process.env.VOIP_AUTO_FAILOVER !== 'false',
}));
