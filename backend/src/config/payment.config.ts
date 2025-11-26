import { registerAs } from '@nestjs/config';

export default registerAs('payment', () => ({
  paystack: {
    secretKey: process.env.PAYSTACK_SECRET_KEY,
    publicKey: process.env.PAYSTACK_PUBLIC_KEY,
  },
  stripe: {
    secretKey: process.env.STRIPE_SECRET_KEY,
    publishableKey: process.env.STRIPE_PUBLISHABLE_KEY,
    webhookSecret: process.env.STRIPE_WEBHOOK_SECRET,
  },
  exchangeRate: {
    ngnToUsd: parseFloat(process.env.NGN_TO_USD_RATE || '1650'),
  },
}));
