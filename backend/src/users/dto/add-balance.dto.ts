import { IsNumber, IsEnum, IsOptional, IsString, Min } from 'class-validator';
import { PaymentMethod } from '../entities/transaction.entity';

export class AddBalanceDto {
  @IsNumber()
  @Min(1)
  amount: number;

  @IsEnum(PaymentMethod)
  paymentMethod: PaymentMethod;

  @IsOptional()
  @IsString()
  paymentReference?: string;

  @IsOptional()
  metadata?: Record<string, any>;
}
