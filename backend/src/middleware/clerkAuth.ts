import { Request, Response, NextFunction } from 'express';
import { clerkClient } from '../config/clerk';
import logger from '../utils/logger';
import User from '../models/User';

export interface AuthRequest extends Request {
  auth?: {
    userId: string;
    sessionId: string;
    clerkId: string;
  };
  user?: User;
}

export const requireAuth = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      res.status(401).json({
        success: false,
        message: 'No authentication token provided'
      });
      return;
    }

    const token = authHeader.substring(7); // Remove 'Bearer ' prefix

    try {
      // Verify the session token with Clerk
      const sessionClaims = await clerkClient.verifyToken(token);

      if (!sessionClaims || !sessionClaims.sub) {
        res.status(401).json({
          success: false,
          message: 'Invalid or expired token'
        });
        return;
      }

      // Get Clerk user
      const clerkUser = await clerkClient.users.getUser(sessionClaims.sub);

      if (!clerkUser) {
        res.status(401).json({
          success: false,
          message: 'User not found'
        });
        return;
      }

      // Find or create user in database
      let user = await User.findOne({ where: { clerkId: clerkUser.id } });

      if (!user) {
        // Create user if doesn't exist
        user = await User.create({
          clerkId: clerkUser.id,
          email: clerkUser.emailAddresses[0]?.emailAddress || '',
          phoneNumber: clerkUser.phoneNumbers[0]?.phoneNumber,
          displayName: `${clerkUser.firstName || ''} ${clerkUser.lastName || ''}`.trim() || clerkUser.username,
          profileImageUrl: clerkUser.imageUrl,
          balance: parseFloat(process.env.INITIAL_BALANCE || '10.00'),
          lastLoginAt: new Date(),
          isActive: true
        });

        logger.info(`New user created from Clerk: ${user.id}`);
      } else {
        // Update last login
        await user.update({ lastLoginAt: new Date() });
      }

      // Attach auth info to request
      req.auth = {
        userId: user.id,
        sessionId: sessionClaims.sid as string,
        clerkId: clerkUser.id
      };
      req.user = user;

      next();
    } catch (error: any) {
      logger.error('Clerk token verification error:', error);
      res.status(401).json({
        success: false,
        message: 'Invalid or expired token'
      });
    }
  } catch (error) {
    logger.error('Auth middleware error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error during authentication'
    });
  }
};

// Optional auth - doesn't fail if no token provided
export const optionalAuth = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    next();
    return;
  }

  // If token exists, verify it
  await requireAuth(req, res, next);
};
