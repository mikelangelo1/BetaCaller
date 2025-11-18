import { Response } from 'express';
import { AuthRequest } from '../middleware/clerkAuth';
import callService from '../services/call.service';
import logger from '../utils/logger';

export class CallController {
  async createCallRecord(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        res.status(401).json({
          success: false,
          message: 'Unauthorized'
        });
        return;
      }

      const { phoneNumber, contactName, callType } = req.body;

      const callRecord = await callService.createCallRecord({
        userId: req.user.id,
        phoneNumber,
        contactName,
        callType: callType || 'outgoing',
        callStatus: 'connecting'
      });

      res.status(201).json({
        success: true,
        message: 'Call record created',
        call: {
          id: callRecord.id,
          phoneNumber: callRecord.phoneNumber,
          contactName: callRecord.contactName,
          callType: callRecord.callType,
          callStatus: callRecord.callStatus,
          timestamp: callRecord.createdAt
        }
      });
    } catch (error) {
      logger.error('Create call record error:', error);
      res.status(500).json({
        success: false,
        message: 'Server error'
      });
    }
  }

  async endCall(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        res.status(401).json({
          success: false,
          message: 'Unauthorized'
        });
        return;
      }

      const { callId } = req.params;
      const { duration, twilioCallSid } = req.body;

      const callRecord = await callService.endCall(
        callId,
        parseInt(duration) || 0,
        twilioCallSid
      );

      res.json({
        success: true,
        message: 'Call ended successfully',
        call: {
          id: callRecord.id,
          duration: callRecord.duration,
          cost: callRecord.cost ? parseFloat(callRecord.cost.toString()) : 0,
          callStatus: callRecord.callStatus
        }
      });
    } catch (error: any) {
      logger.error('End call error:', error);
      res.status(500).json({
        success: false,
        message: error.message || 'Server error'
      });
    }
  }

  async getCallHistory(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        res.status(401).json({
          success: false,
          message: 'Unauthorized'
        });
        return;
      }

      const limit = parseInt(req.query.limit as string) || 20;
      const offset = parseInt(req.query.offset as string) || 0;

      const { calls, total } = await callService.getCallHistory(
        req.user.id,
        limit,
        offset
      );

      res.json({
        success: true,
        calls: calls.map(call => ({
          id: call.id,
          phoneNumber: call.phoneNumber,
          contactName: call.contactName,
          callType: call.callType,
          callStatus: call.callStatus,
          duration: call.duration,
          cost: call.cost ? parseFloat(call.cost.toString()) : 0,
          timestamp: call.createdAt
        })),
        pagination: {
          total,
          limit,
          offset,
          hasMore: offset + limit < total
        }
      });
    } catch (error) {
      logger.error('Get call history error:', error);
      res.status(500).json({
        success: false,
        message: 'Server error'
      });
    }
  }

  async deleteCallRecord(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        res.status(401).json({
          success: false,
          message: 'Unauthorized'
        });
        return;
      }

      const { callId } = req.params;

      await callService.deleteCallRecord(callId, req.user.id);

      res.json({
        success: true,
        message: 'Call record deleted successfully'
      });
    } catch (error: any) {
      logger.error('Delete call record error:', error);
      res.status(500).json({
        success: false,
        message: error.message || 'Server error'
      });
    }
  }

  async getCallStatistics(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        res.status(401).json({
          success: false,
          message: 'Unauthorized'
        });
        return;
      }

      const stats = await callService.getCallStatistics(req.user.id);

      res.json({
        success: true,
        statistics: stats
      });
    } catch (error) {
      logger.error('Get call statistics error:', error);
      res.status(500).json({
        success: false,
        message: 'Server error'
      });
    }
  }
}

export default new CallController();
