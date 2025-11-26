import { Injectable, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Transaction, TransactionType, TransactionStatus, PaymentMethod } from './entities/transaction.entity';
import { User } from './entities/user.entity';
import { AddBalanceDto } from './dto/add-balance.dto';
import { TransactionQueryDto } from './dto/transaction-query.dto';

@Injectable()
export class TransactionsService {
  constructor(
    @InjectRepository(Transaction)
    private transactionsRepository: Repository<Transaction>,
    @InjectRepository(User)
    private usersRepository: Repository<User>,
  ) {}

  async findAll(userId: string, query: TransactionQueryDto) {
    const { limit = 20, offset = 0, type, status } = query;

    const queryBuilder = this.transactionsRepository
      .createQueryBuilder('transaction')
      .where('transaction.user_id = :userId', { userId })
      .orderBy('transaction.created_at', 'DESC')
      .take(limit)
      .skip(offset);

    if (type) {
      queryBuilder.andWhere('transaction.type = :type', { type });
    }

    if (status) {
      queryBuilder.andWhere('transaction.status = :status', { status });
    }

    const [transactions, total] = await queryBuilder.getManyAndCount();

    return {
      transactions: transactions.map(t => t.toSafeObject()),
      total,
      limit,
      offset,
    };
  }

  async findOne(id: string, userId: string) {
    const transaction = await this.transactionsRepository.findOne({
      where: { id, userId },
    });

    if (!transaction) {
      throw new BadRequestException('Transaction not found');
    }

    return transaction.toSafeObject();
  }

  async addBalance(userId: string, addBalanceDto: AddBalanceDto) {
    const { amount, paymentMethod, paymentReference, metadata } = addBalanceDto;

    // Find user
    const user = await this.usersRepository.findOne({ where: { id: userId } });
    if (!user) {
      throw new BadRequestException('User not found');
    }

    const balanceBefore = parseFloat(user.balance.toString());
    const balanceAfter = balanceBefore + amount;

    // Create transaction
    const transaction = this.transactionsRepository.create({
      userId,
      type: TransactionType.CREDIT,
      amount,
      balanceBefore,
      balanceAfter,
      status: TransactionStatus.COMPLETED, // In real app, this would be PENDING until payment is confirmed
      paymentMethod,
      paymentReference: paymentReference || `PAY-${Date.now()}`,
      description: `Added balance via ${paymentMethod}`,
      metadata,
    });

    await this.transactionsRepository.save(transaction);

    // Update user balance
    user.balance = balanceAfter;
    await this.usersRepository.save(user);

    return {
      transaction: transaction.toSafeObject(),
      newBalance: balanceAfter,
    };
  }

  async deductBalance(
    userId: string,
    amount: number,
    description: string,
    callId?: string,
  ) {
    // Find user
    const user = await this.usersRepository.findOne({ where: { id: userId } });
    if (!user) {
      throw new BadRequestException('User not found');
    }

    const balanceBefore = parseFloat(user.balance.toString());
    const balanceAfter = balanceBefore - amount;

    if (balanceAfter < 0) {
      throw new BadRequestException('Insufficient balance');
    }

    // Create transaction
    const transaction = this.transactionsRepository.create({
      userId,
      type: TransactionType.DEBIT,
      amount,
      balanceBefore,
      balanceAfter,
      status: TransactionStatus.COMPLETED,
      description,
      callId,
    });

    await this.transactionsRepository.save(transaction);

    // Update user balance
    user.balance = balanceAfter;
    await this.usersRepository.save(user);

    return {
      transaction: transaction.toSafeObject(),
      newBalance: balanceAfter,
    };
  }

  async getStatistics(userId: string) {
    const totalCredit = await this.transactionsRepository
      .createQueryBuilder('transaction')
      .select('SUM(transaction.amount)', 'total')
      .where('transaction.user_id = :userId', { userId })
      .andWhere('transaction.type = :type', { type: TransactionType.CREDIT })
      .andWhere('transaction.status = :status', { status: TransactionStatus.COMPLETED })
      .getRawOne();

    const totalDebit = await this.transactionsRepository
      .createQueryBuilder('transaction')
      .select('SUM(transaction.amount)', 'total')
      .where('transaction.user_id = :userId', { userId })
      .andWhere('transaction.type = :type', { type: TransactionType.DEBIT })
      .andWhere('transaction.status = :status', { status: TransactionStatus.COMPLETED })
      .getRawOne();

    const transactionCount = await this.transactionsRepository.count({
      where: { userId },
    });

    return {
      totalAdded: parseFloat(totalCredit?.total || '0'),
      totalSpent: parseFloat(totalDebit?.total || '0'),
      transactionCount,
    };
  }
}
