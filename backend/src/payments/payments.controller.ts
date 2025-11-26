import {
  Controller,
  Post,
  Get,
  Body,
  Headers,
  RawBodyRequest,
  Req,
  UseGuards,
  HttpCode,
  HttpStatus,
  BadRequestException,
} from '@nestjs/common';
import { Request } from 'express';
import { PaymentsService } from './payments.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

@Controller('payments')
export class PaymentsController {
  constructor(private readonly paymentsService: PaymentsService) {}

  /**
   * Get current exchange rate
   */
  @Get('exchange-rate')
  getExchangeRate() {
    const { rate, updatedAt } = this.paymentsService.getExchangeRate();
    return {
      success: true,
      rate,
      updatedAt,
    };
  }

  /**
   * Create Stripe Payment Intent
   */
  @Post('stripe/create-payment-intent')
  @UseGuards(JwtAuthGuard)
  async createStripePaymentIntent(
    @CurrentUser() user: any,
    @Body() body: {
      amount: number;
      currency: string;
      email: string;
      metadata?: Record<string, any>;
    },
  ) {
    try {
      const { amount, currency, email, metadata } = body;

      if (!amount || amount <= 0) {
        throw new BadRequestException('Invalid amount');
      }

      if (!currency || !['usd', 'USD'].includes(currency)) {
        throw new BadRequestException('Only USD is supported for Stripe payments');
      }

      const result = await this.paymentsService.createStripePaymentIntent(
        user.id,
        amount,
        currency,
        email,
        metadata,
      );

      return {
        success: true,
        ...result,
      };
    } catch (error) {
      return {
        success: false,
        error: error.message,
      };
    }
  }

  /**
   * Verify Stripe Payment
   */
  @Post('stripe/verify')
  @UseGuards(JwtAuthGuard)
  async verifyStripePayment(
    @CurrentUser() user: any,
    @Body() body: { paymentIntentId: string },
  ) {
    try {
      const { paymentIntentId } = body;

      if (!paymentIntentId) {
        throw new BadRequestException('Payment intent ID is required');
      }

      return await this.paymentsService.verifyStripePayment(user.id, paymentIntentId);
    } catch (error) {
      return {
        success: false,
        error: error.message,
      };
    }
  }

  /**
   * Initialize Paystack Payment
   */
  @Post('paystack/initialize')
  @UseGuards(JwtAuthGuard)
  async initializePaystackPayment(
    @CurrentUser() user: any,
    @Body() body: {
      amount: number;
      email: string;
      reference: string;
      metadata?: Record<string, any>;
    },
  ) {
    try {
      const { amount, email, reference, metadata } = body;

      if (!amount || amount <= 0) {
        throw new BadRequestException('Invalid amount');
      }

      if (!email) {
        throw new BadRequestException('Email is required');
      }

      const result = await this.paymentsService.initializePaystackPayment(
        user.id,
        amount,
        email,
        reference,
        metadata,
      );

      return {
        success: true,
        ...result,
      };
    } catch (error) {
      return {
        success: false,
        error: error.message,
      };
    }
  }

  /**
   * Verify Paystack Payment
   */
  @Post('paystack/verify')
  @UseGuards(JwtAuthGuard)
  async verifyPaystackPayment(
    @CurrentUser() user: any,
    @Body() body: { reference: string },
  ) {
    try {
      const { reference } = body;

      if (!reference) {
        throw new BadRequestException('Payment reference is required');
      }

      return await this.paymentsService.verifyPaystackPayment(user.id, reference);
    } catch (error) {
      return {
        success: false,
        error: error.message,
      };
    }
  }

  /**
   * Stripe Webhook Handler
   */
  @Post('stripe/webhook')
  @HttpCode(HttpStatus.OK)
  async handleStripeWebhook(
    @Headers('stripe-signature') signature: string,
    @Req() req: RawBodyRequest<Request>,
  ) {
    try {
      if (!signature) {
        throw new BadRequestException('Missing stripe-signature header');
      }

      if (!req.rawBody) {
        throw new BadRequestException('Missing request body');
      }

      await this.paymentsService.handleStripeWebhook(signature, req.rawBody);

      return { received: true };
    } catch (error) {
      throw new BadRequestException(`Webhook Error: ${error.message}`);
    }
  }

  /**
   * Paystack Webhook Handler
   */
  @Post('paystack/webhook')
  @HttpCode(HttpStatus.OK)
  async handlePaystackWebhook(
    @Headers('x-paystack-signature') signature: string,
    @Body() payload: any,
  ) {
    try {
      if (!signature) {
        throw new BadRequestException('Missing x-paystack-signature header');
      }

      await this.paymentsService.handlePaystackWebhook(signature, payload);

      return { received: true };
    } catch (error) {
      throw new BadRequestException(`Webhook Error: ${error.message}`);
    }
  }
}
