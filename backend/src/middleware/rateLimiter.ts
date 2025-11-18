import rateLimit from 'express-rate-limit';

export const apiLimiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS || '900000'), // 15 minutes
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS || '100'),
  message: {
    success: false,
    message: 'Too many requests from this IP, please try again later.'
  },
  standardHeaders: true,
  legacyHeaders: false
});

export const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 10,
  message: {
    success: false,
    message: 'Too many authentication attempts, please try again later.'
  },
  skipSuccessfulRequests: true
});

export const callLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 5, // 5 calls per minute max
  message: {
    success: false,
    message: 'Too many call attempts, please try again later.'
  }
});

export default apiLimiter;
