import { Transaction as DbTransaction } from 'sequelize';
import User from '../models/User';
import Transaction from '../models/Transaction';
import { sequelize } from '../config/database';
import logger from '../utils/logger';

export class BalanceService {
  async getBalance(userId: string): Promise<number> {
    const user = await User.findByPk(userId);
    if (!user) {
      throw new Error('User not found');
    }
    return parseFloat(user.balance.toString());
  }

  async addBalance(
    userId: string,
    amount: number,
    description?: string
  ): Promise<{ newBalance: number; transaction: Transaction }> {
    return await sequelize.transaction(async (t: DbTransaction) => {
      const user = await User.findByPk(userId, { transaction: t });
      if (!user) {
        throw new Error('User not found');
      }

      const oldBalance = parseFloat(user.balance.toString());
      const newBalance = oldBalance + amount;

      await user.update({ balance: newBalance }, { transaction: t });

      const transaction = await Transaction.create(
        {
          userId,
          type: 'credit',
          amount,
          description: description || 'Balance added',
          balanceBefore: oldBalance,
          balanceAfter: newBalance
        },
        { transaction: t }
      );

      logger.info(`Balance added for user ${userId}: $${amount}`);

      return { newBalance, transaction };
    });
  }

  async deductBalance(
    userId: string,
    amount: number,
    description?: string,
    referenceType?: string,
    referenceId?: string
  ): Promise<{ newBalance: number; transaction: Transaction }> {
    return await sequelize.transaction(async (t: DbTransaction) => {
      const user = await User.findByPk(userId, { transaction: t, lock: true });
      if (!user) {
        throw new Error('User not found');
      }

      const oldBalance = parseFloat(user.balance.toString());

      if (oldBalance < amount) {
        throw new Error('Insufficient balance');
      }

      const newBalance = oldBalance - amount;

      await user.update({ balance: newBalance }, { transaction: t });

      const transaction = await Transaction.create(
        {
          userId,
          type: 'debit',
          amount,
          description: description || 'Balance deducted',
          referenceType,
          referenceId,
          balanceBefore: oldBalance,
          balanceAfter: newBalance
        },
        { transaction: t }
      );

      logger.info(`Balance deducted for user ${userId}: $${amount}`);

      return { newBalance, transaction };
    });
  }

  async getTransactionHistory(
    userId: string,
    limit: number = 20,
    offset: number = 0
  ): Promise<{ transactions: Transaction[]; total: number }> {
    const { rows, count } = await Transaction.findAndCountAll({
      where: { userId },
      order: [['createdAt', 'DESC']],
      limit,
      offset
    });

    return {
      transactions: rows,
      total: count
    };
  }

  async canAfford(userId: string, amount: number): Promise<boolean> {
    const balance = await this.getBalance(userId);
    return balance >= amount;
  }
}

export default new BalanceService();
