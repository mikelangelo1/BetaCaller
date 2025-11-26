import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { User } from './entities/user.entity';
import { Transaction } from './entities/transaction.entity';
import { UsersService } from './users.service';
import { UsersController } from './users.controller';
import { TransactionsService } from './transactions.service';
import { TransactionsController } from './transactions.controller';

@Module({
  imports: [TypeOrmModule.forFeature([User, Transaction])],
  controllers: [UsersController, TransactionsController],
  providers: [UsersService, TransactionsService],
  exports: [UsersService, TransactionsService],
})
export class UsersModule {}
