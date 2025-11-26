import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { User } from './user.entity';

export enum TransactionType {
  CREDIT = 'credit', // Adding balance
  DEBIT = 'debit',   // Call charges
}

export enum TransactionStatus {
  PENDING = 'pending',
  COMPLETED = 'completed',
  FAILED = 'failed',
  REFUNDED = 'refunded',
}

export enum PaymentMethod {
  CARD = 'card',
  PAYPAL = 'paypal',
  APPLE_PAY = 'apple_pay',
  GOOGLE_PAY = 'google_pay',
  PAYSTACK = 'paystack',
  STRIPE = 'stripe',
}

@Entity('transactions')
export class Transaction {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id' })
  userId: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'user_id' })
  user: User;

  @Column({
    type: 'enum',
    enum: TransactionType,
  })
  type: TransactionType;

  @Column({ type: 'decimal', precision: 10, scale: 2 })
  amount: number;

  @Column({ type: 'decimal', precision: 10, scale: 2, name: 'balance_before' })
  balanceBefore: number;

  @Column({ type: 'decimal', precision: 10, scale: 2, name: 'balance_after' })
  balanceAfter: number;

  @Column({
    type: 'enum',
    enum: TransactionStatus,
    default: TransactionStatus.PENDING,
  })
  status: TransactionStatus;

  @Column({
    type: 'enum',
    enum: PaymentMethod,
    nullable: true,
    name: 'payment_method',
  })
  paymentMethod: PaymentMethod;

  @Column({ type: 'text', nullable: true })
  description: string;

  @Column({ nullable: true, name: 'call_id' })
  callId: string;

  @Column({ nullable: true, name: 'payment_reference' })
  paymentReference: string;

  @Column({ type: 'json', nullable: true })
  metadata: Record<string, any>;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  toSafeObject() {
    return {
      id: this.id,
      userId: this.userId,
      type: this.type,
      amount: parseFloat(this.amount.toString()),
      balanceBefore: parseFloat(this.balanceBefore.toString()),
      balanceAfter: parseFloat(this.balanceAfter.toString()),
      status: this.status,
      paymentMethod: this.paymentMethod,
      description: this.description,
      callId: this.callId,
      paymentReference: this.paymentReference,
      metadata: this.metadata,
      createdAt: this.createdAt,
    };
  }
}
