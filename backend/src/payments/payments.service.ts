import { Injectable, Logger, BadRequestException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import Stripe from 'stripe';
import * as crypto from 'crypto';
import axios from 'axios';
import { Transaction, TransactionType, TransactionStatus, PaymentMethod } from '../users/entities/transaction.entity';
import { User } from '../users/entities/user.entity';

@Injectable()
export class PaymentsService {
  private readonly logger = new Logger(PaymentsService.name);
  private stripe: Stripe | null = null;
  private paystackSecretKey: string;
  private exchangeRate: number;

  constructor(
    private configService: ConfigService,
    @InjectRepository(Transaction)
    private transactionRepository: Repository<Transaction>,
    @InjectRepository(User)
    private userRepository: Repository<User>,
  ) {
    // Initialize Stripe
    const stripeSecretKey = this.configService.get<string>('payment.stripe.secretKey');
    if (stripeSecretKey) {
      this.stripe = new Stripe(stripeSecretKey);
      this.logger.log('Stripe initialized');
    } else {
      this.logger.warn('Stripe secret key not configured');
    }

    // Initialize Paystack
    this.paystackSecretKey = this.configService.get<string>('payment.paystack.secretKey') || '';

    if (this.paystackSecretKey) {
      this.logger.log('Paystack configured');
    } else {
      this.logger.warn('Paystack secret key not configured');
    }

    // Get exchange rate
    this.exchangeRate = this.configService.get<number>('payment.exchangeRate.ngnToUsd') || 1650;
  }

  /**
   * Get current exchange rate
   */
  getExchangeRate(): { rate: number; updatedAt: Date } {
    return {
      rate: this.exchangeRate,
      updatedAt: new Date(),
    };
  }

  /**
   * Create Stripe Payment Intent
   */
  async createStripePaymentIntent(
    userId: string,
    amount: number,
    currency: string,
    email: string,
    metadata?: Record<string, any>,
  ): Promise<{
    clientSecret: string;
    paymentIntentId: string;
    customerId?: string;
    ephemeralKey?: string;
  }> {
    if (!this.stripe) {
      throw new BadRequestException('Stripe is not configured');
    }

    const user = await this.userRepository.findOne({ where: { id: userId } });
    if (!user) {
      throw new BadRequestException('User not found');
    }

    let customerId = user.stripeCustomerId;

    if (!customerId) {
      const customer = await this.stripe.customers.create({
        email: email,
        metadata: { userId: userId },
      });
      customerId = customer.id;
      user.stripeCustomerId = customerId;
      await this.userRepository.save(user);
    }

    const ephemeralKey = await this.stripe.ephemeralKeys.create(
      { customer: customerId },
      { apiVersion: '2025-11-17.clover' }
    );

    const amountInCents = Math.round(amount * 100);

    const paymentIntent = await this.stripe.paymentIntents.create({
      amount: amountInCents,
      currency: currency.toLowerCase(),
      customer: customerId,
      metadata: {
        userId: userId,
        type: 'balance_topup',
        ...metadata,
      },
      automatic_payment_methods: { enabled: true },
    });

    this.logger.log(`Stripe payment intent created: ${paymentIntent.id}`);

    return {
      clientSecret: paymentIntent.client_secret!,
      paymentIntentId: paymentIntent.id,
      customerId: customerId,
      ephemeralKey: ephemeralKey.secret,
    };
  }

  /**
   * Verify Stripe Payment
   */
  async verifyStripePayment(
    userId: string,
    paymentIntentId: string,
  ): Promise<{
    success: boolean;
    transactionId?: string;
    amount?: number;
    currency?: string;
    error?: string;
  }> {
    try {
      if (!this.stripe) {
        throw new BadRequestException('Stripe is not configured');
      }

      const paymentIntent = await this.stripe.paymentIntents.retrieve(paymentIntentId);

      if (paymentIntent.status === 'succeeded') {
        const existingTransaction = await this.transactionRepository.findOne({
          where: { paymentReference: paymentIntentId },
        });

        if (existingTransaction) {
          return {
            success: true,
            transactionId: existingTransaction.id,
            amount: existingTransaction.amount,
            currency: 'USD',
          };
        }

        const amountInUSD = paymentIntent.amount / 100;

        const user = await this.userRepository.findOne({ where: { id: userId } });
        if (!user) {
          throw new BadRequestException('User not found');
        }

        const balanceBefore = parseFloat(user.balance?.toString() || '0');
        const balanceAfter = balanceBefore + amountInUSD;

        const transaction = this.transactionRepository.create({
          userId: userId,
          type: TransactionType.CREDIT,
          amount: amountInUSD,
          balanceBefore: balanceBefore,
          balanceAfter: balanceAfter,
          status: TransactionStatus.COMPLETED,
          description: `Balance top-up via Stripe`,
          paymentMethod: PaymentMethod.STRIPE,
          paymentReference: paymentIntentId,
          metadata: {
            currency: paymentIntent.currency.toUpperCase(),
            paymentIntentId: paymentIntentId,
          },
        });

        const savedTransaction = await this.transactionRepository.save(transaction);

        user.balance = balanceAfter;
        await this.userRepository.save(user);
        this.logger.log(`User ${userId} balance updated: +$${amountInUSD}`);

        return {
          success: true,
          transactionId: savedTransaction.id,
          amount: amountInUSD,
          currency: 'USD',
        };
      } else {
        return {
          success: false,
          error: `Payment not succeeded. Status: ${paymentIntent.status}`,
        };
      }
    } catch (error: any) {
      this.logger.error('Failed to verify Stripe payment', error);
      return {
        success: false,
        error: error.message,
      };
    }
  }

  /**
   * Initialize Paystack Payment
   */
  async initializePaystackPayment(
    userId: string,
    amount: number,
    email: string,
    reference: string,
    metadata?: Record<string, any>,
  ): Promise<{
    authorizationUrl: string;
    accessCode: string;
    reference: string;
  }> {
    if (!this.paystackSecretKey) {
      throw new BadRequestException('Paystack is not configured');
    }

    const response = await axios.post(
      'https://api.paystack.co/transaction/initialize',
      {
        amount,
        email,
        reference,
        currency: 'NGN',
        metadata: {
          userId,
          type: 'balance_topup',
          ...metadata,
        },
        callback_url: `${process.env.FRONTEND_URL}/payment/callback`,
      },
      {
        headers: {
          Authorization: `Bearer ${this.paystackSecretKey}`,
          'Content-Type': 'application/json',
        },
      }
    );

    if (response.data?.status && response.data?.data) {
      const data = response.data.data;
      this.logger.log(`Paystack payment initialized: ${reference}`);

      return {
        authorizationUrl: data.authorization_url,
        accessCode: data.access_code,
        reference: data.reference,
      };
    }

    throw new BadRequestException('Failed to initialize Paystack payment');
  }

  /**
   * Verify Paystack Payment
   */
  async verifyPaystackPayment(
    userId: string,
    reference: string,
  ): Promise<{
    success: boolean;
    transactionId?: string;
    amount?: number;
    currency?: string;
    error?: string;
  }> {
    try {
      if (!this.paystackSecretKey) {
        throw new BadRequestException('Paystack is not configured');
      }

      const response = await axios.get(
        `https://api.paystack.co/transaction/verify/${reference}`,
        {
          headers: {
            Authorization: `Bearer ${this.paystackSecretKey}`,
          },
        }
      );

      if (response.data?.status && response.data?.data) {
        const paymentData = response.data.data;

        if (paymentData.status === 'success') {
          const existingTransaction = await this.transactionRepository.findOne({
            where: { paymentReference: reference },
          });

          if (existingTransaction) {
            return {
              success: true,
              transactionId: existingTransaction.id,
              amount: existingTransaction.amount,
              currency: 'NGN',
            };
          }

          const amountInNaira = paymentData.amount / 100;
          const amountInUSD = amountInNaira / this.exchangeRate;

          const user = await this.userRepository.findOne({ where: { id: userId } });
          if (!user) {
            throw new BadRequestException('User not found');
          }

          const balanceBefore = parseFloat(user.balance?.toString() || '0');
          const balanceAfter = balanceBefore + amountInUSD;

          const transaction = this.transactionRepository.create({
            userId: userId,
            type: TransactionType.CREDIT,
            amount: amountInUSD,
            balanceBefore: balanceBefore,
            balanceAfter: balanceAfter,
            status: TransactionStatus.COMPLETED,
            description: `Balance top-up via Paystack (₦${amountInNaira.toFixed(2)})`,
            paymentMethod: PaymentMethod.PAYSTACK,
            paymentReference: reference,
            metadata: {
              currency: 'NGN',
              amountInNaira: amountInNaira,
              exchangeRate: this.exchangeRate,
              paystackReference: reference,
            },
          });

          const savedTransaction = await this.transactionRepository.save(transaction);

          user.balance = balanceAfter;
          await this.userRepository.save(user);
          this.logger.log(`User ${userId} balance updated: +$${amountInUSD.toFixed(4)} (₦${amountInNaira})`);

          return {
            success: true,
            transactionId: savedTransaction.id,
            amount: amountInNaira,
            currency: 'NGN',
          };
        } else {
          return {
            success: false,
            error: `Payment not successful. Status: ${paymentData.status}`,
          };
        }
      } else {
        return {
          success: false,
          error: 'Invalid response from Paystack',
        };
      }
    } catch (error: any) {
      this.logger.error('Failed to verify Paystack payment', error);
      return {
        success: false,
        error: error.response?.data?.message || error.message,
      };
    }
  }

  /**
   * Handle Stripe Webhook
   */
  async handleStripeWebhook(signature: string, payload: Buffer): Promise<void> {
    if (!this.stripe) {
      throw new BadRequestException('Stripe is not configured');
    }

    const webhookSecret = this.configService.get<string>('payment.stripe.webhookSecret');
    if (!webhookSecret) {
      this.logger.warn('Stripe webhook secret not configured');
      return;
    }

    const event = this.stripe.webhooks.constructEvent(
      payload,
      signature,
      webhookSecret
    );

    this.logger.log(`Stripe webhook received: ${event.type}`);

    switch (event.type) {
      case 'payment_intent.succeeded':
        this.logger.log(`Stripe payment succeeded: ${(event.data.object as Stripe.PaymentIntent).id}`);
        break;
      case 'payment_intent.payment_failed':
        this.logger.error(`Stripe payment failed: ${(event.data.object as Stripe.PaymentIntent).id}`);
        break;
      default:
        this.logger.log(`Unhandled Stripe event type: ${event.type}`);
    }
  }

  /**
   * Handle Paystack Webhook
   */
  async handlePaystackWebhook(signature: string, payload: any): Promise<void> {
    if (!this.paystackSecretKey) {
      throw new BadRequestException('Paystack is not configured');
    }

    const hash = crypto
      .createHmac('sha512', this.paystackSecretKey)
      .update(JSON.stringify(payload))
      .digest('hex');

    if (hash !== signature) {
      throw new BadRequestException('Invalid signature');
    }

    this.logger.log(`Paystack webhook received: ${payload.event}`);

    switch (payload.event) {
      case 'charge.success':
        this.logger.log(`Paystack charge succeeded: ${payload.data?.reference}`);
        break;
      default:
        this.logger.log(`Unhandled Paystack event type: ${payload.event}`);
    }
  }
}
