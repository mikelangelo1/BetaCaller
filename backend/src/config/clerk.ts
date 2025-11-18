import { clerkClient } from '@clerk/clerk-sdk-node';

if (!process.env.CLERK_SECRET_KEY) {
  throw new Error('CLERK_SECRET_KEY is required');
}

export { clerkClient };
export const CLERK_SECRET_KEY = process.env.CLERK_SECRET_KEY;
export const CLERK_PUBLISHABLE_KEY = process.env.CLERK_PUBLISHABLE_KEY;
