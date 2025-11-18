import { Response } from 'express';
import { AuthRequest } from '../middleware/clerkAuth';
import { clerkClient } from '../config/clerk';
import logger from '../utils/logger';

export class AuthController {
  async getProfile(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        res.status(401).json({
          success: false,
          message: 'Unauthorized'
        });
        return;
      }

      res.json({
        success: true,
        user: {
          id: req.user.id,
          clerkId: req.user.clerkId,
          email: req.user.email,
          phoneNumber: req.user.phoneNumber,
          displayName: req.user.displayName,
          profileImageUrl: req.user.profileImageUrl,
          balance: parseFloat(req.user.balance.toString()),
          lastLoginAt: req.user.lastLoginAt,
          createdAt: req.user.createdAt
        }
      });
    } catch (error) {
      logger.error('Get profile error:', error);
      res.status(500).json({
        success: false,
        message: 'Server error'
      });
    }
  }

  async updateProfile(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        res.status(401).json({
          success: false,
          message: 'Unauthorized'
        });
        return;
      }

      const { displayName, phoneNumber } = req.body;

      await req.user.update({
        displayName,
        phoneNumber
      });

      res.json({
        success: true,
        message: 'Profile updated successfully',
        user: {
          id: req.user.id,
          email: req.user.email,
          phoneNumber: req.user.phoneNumber,
          displayName: req.user.displayName,
          profileImageUrl: req.user.profileImageUrl
        }
      });
    } catch (error) {
      logger.error('Update profile error:', error);
      res.status(500).json({
        success: false,
        message: 'Server error'
      });
    }
  }

  async deleteAccount(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user || !req.auth) {
        res.status(401).json({
          success: false,
          message: 'Unauthorized'
        });
        return;
      }

      // Delete from Clerk
      await clerkClient.users.deleteUser(req.auth.clerkId);

      // Soft delete in database
      await req.user.update({ isActive: false });

      logger.info(`User account deleted: ${req.user.id}`);

      res.json({
        success: true,
        message: 'Account deleted successfully'
      });
    } catch (error) {
      logger.error('Delete account error:', error);
      res.status(500).json({
        success: false,
        message: 'Server error'
      });
    }
  }
}

export default new AuthController();
