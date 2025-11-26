import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Query,
  UseGuards,
  Request,
} from '@nestjs/common';
import { TransactionsService } from './transactions.service';
import { AddBalanceDto } from './dto/add-balance.dto';
import { TransactionQueryDto } from './dto/transaction-query.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Controller('transactions')
@UseGuards(JwtAuthGuard)
export class TransactionsController {
  constructor(private readonly transactionsService: TransactionsService) {}

  @Get()
  async findAll(@Request() req, @Query() query: TransactionQueryDto) {
    return this.transactionsService.findAll(req.user.id, query);
  }

  @Get('statistics')
  async getStatistics(@Request() req) {
    return this.transactionsService.getStatistics(req.user.id);
  }

  @Get(':id')
  async findOne(@Request() req, @Param('id') id: string) {
    return this.transactionsService.findOne(id, req.user.id);
  }

  @Post('add-balance')
  async addBalance(@Request() req, @Body() addBalanceDto: AddBalanceDto) {
    return this.transactionsService.addBalance(req.user.id, addBalanceDto);
  }
}
