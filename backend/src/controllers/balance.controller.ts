import { Response } from 'express';
import { AuthRequest } from '../middleware/clerkAuth';
import balanceService from '../services/balance.service';
import logger from '../utils/logger';

export class BalanceController {
  async getBalance(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        res.status(401).json({
          success: false,
          message: 'Unauthorized'
        });
        return;
      }

      const balance = await balanceService.getBalance(req.user.id);

      res.json({
        success: true,
        balance
      });
    } catch (error) {
      logger.error('Get balance error:', error);
      res.status(500).json({
        success: false,
        message: 'Server error'
      });
    }
  }

  async addBalance(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        res.status(401).json({
          success: false,
          message: 'Unauthorized'
        });
        return;
      }

      const { amount } = req.body;

      if (!amount || amount <= 0) {
        res.status(400).json({
          success: false,
          message: 'Invalid amount'
        });
        return;
      }

      const { newBalance, transaction } = await balanceService.addBalance(
        req.user.id,
        parseFloat(amount)
      );

      res.json({
        success: true,
        message: 'Balance added successfully',
        newBalance,
        transaction: {
          id: transaction.id,
          amount: parseFloat(transaction.amount.toString()),
          type: transaction.type,
          timestamp: transaction.createdAt
        }
      });
    } catch (error) {
      logger.error('Add balance error:', error);
      res.status(500).json({
        success: false,
        message: 'Server error'
      });
    }
  }

  async getTransactionHistory(req: AuthRequest, res: Response): Promise<void> {
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

      const { transactions, total } = await balanceService.getTransactionHistory(
        req.user.id,
        limit,
        offset
      );

      res.json({
        success: true,
        transactions: transactions.map(t => ({
          id: t.id,
          type: t.type,
          amount: parseFloat(t.amount.toString()),
          description: t.description,
          balanceBefore: t.balanceBefore ? parseFloat(t.balanceBefore.toString()) : null,
          balanceAfter: t.balanceAfter ? parseFloat(t.balanceAfter.toString()) : null,
          timestamp: t.createdAt
        })),
        pagination: {
          total,
          limit,
          offset,
          hasMore: offset + limit < total
        }
      });
    } catch (error) {
      logger.error('Get transaction history error:', error);
      res.status(500).json({
        success: false,
        message: 'Server error'
      });
    }
  }
}

export default new BalanceController();
