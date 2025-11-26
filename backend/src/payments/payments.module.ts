import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ConfigModule } from '@nestjs/config';
import { PaymentsController } from './payments.controller';
import { PaymentsService } from './payments.service';
import { Transaction } from '../users/entities/transaction.entity';
import { User } from '../users/entities/user.entity';
import paymentConfig from '../config/payment.config';

@Module({
  imports: [
    ConfigModule.forFeature(paymentConfig),
    TypeOrmModule.forFeature([Transaction, User]),
  ],
  controllers: [PaymentsController],
  providers: [PaymentsService],
  exports: [PaymentsService],
})
export class PaymentsModule {}
