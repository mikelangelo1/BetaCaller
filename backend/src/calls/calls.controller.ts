import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Query,
  UseGuards,
  Request,
  Headers,
  RawBodyRequest,
  Req,
} from '@nestjs/common';
import { CallsService } from './calls.service';
import { RateCalculatorService } from './rate-calculator.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Controller('calls')
export class CallsController {
  constructor(
    private readonly callsService: CallsService,
    private readonly rateCalculatorService: RateCalculatorService,
  ) {}

  @Get('token')
  @UseGuards(JwtAuthGuard)
  async getToken(@Request() req) {
    return this.callsService.generateToken(req.user.id);
  }

  @Post('initiate')
  @UseGuards(JwtAuthGuard)
  async initiateCall(
    @Request() req,
    @Body() body: { to: string; from?: string },
  ) {
    return this.callsService.initiateCall({
      userId: req.user.id,
      to: body.to,
      from: body.from,
    });
  }

  @Get('rate/:phoneNumber')
  @UseGuards(JwtAuthGuard)
  async getRate(@Param('phoneNumber') phoneNumber: string) {
    return this.rateCalculatorService.getRate(phoneNumber);
  }

  @Get('estimate-cost')
  @UseGuards(JwtAuthGuard)
  async estimateCost(
    @Query('phoneNumber') phoneNumber: string,
    @Query('minutes') minutes?: string,
  ) {
    const durationMinutes = minutes ? parseFloat(minutes) : 1;
    return this.callsService.estimateCallCost(phoneNumber, durationMinutes);
  }

  @Get('history')
  @UseGuards(JwtAuthGuard)
  async getHistory(
    @Request() req,
    @Query('limit') limit?: string,
    @Query('offset') offset?: string,
  ) {
    const parsedLimit = limit ? parseInt(limit) : 50;
    const parsedOffset = offset ? parseInt(offset) : 0;

    return this.callsService.getCallHistory(req.user.id, parsedLimit, parsedOffset);
  }

  @Get('statistics')
  @UseGuards(JwtAuthGuard)
  async getStatistics(@Request() req) {
    return this.callsService.getCallStatistics(req.user.id);
  }

  @Post('webhook')
  async handleWebhook(
    @Req() req: RawBodyRequest<Request>,
    @Headers('telnyx-signature-ed25519') signature: string,
    @Headers('telnyx-timestamp') timestamp: string,
    @Body() body: any,
  ) {
    // Verify webhook signature
    // const rawBody = req.rawBody?.toString() || JSON.stringify(body);
    // const isValid = this.telnyxService.verifyWebhookSignature(rawBody, signature, timestamp);

    // if (!isValid) {
    //   throw new BadRequestException('Invalid webhook signature');
    // }

    return this.callsService.handleWebhook(body);
  }
}
