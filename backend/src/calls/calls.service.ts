import { Injectable, Logger, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { CallRecord, CallStatus, CallDirection } from './entities/call-record.entity';
import { VoipProviderManager, VoipProviderType, VoipWebhookPayload } from './providers';
import { RateCalculatorService } from './rate-calculator.service';
import { TransactionsService } from '../users/transactions.service';
import { UsersService } from '../users/users.service';

export interface InitiateCallDto {
  to: string;
  from?: string;
  userId: string;
}

@Injectable()
export class CallsService {
  private readonly logger = new Logger(CallsService.name);

  constructor(
    @InjectRepository(CallRecord)
    private callRecordRepository: Repository<CallRecord>,
    private voipManager: VoipProviderManager,
    private rateCalculatorService: RateCalculatorService,
    private transactionsService: TransactionsService,
    private usersService: UsersService,
  ) {}

  /**
   * Generate RTC token for WebRTC calling
   * Uses the active VoIP provider with automatic failover
   */
  async generateToken(userId: string): Promise<{
    token: string;
    expiresIn: number;
    provider: string;
    providerConfig?: any;
  }> {
    const result = await this.voipManager.generateToken(userId);

    return {
      token: result.token,
      expiresIn: result.expiresIn,
      provider: result.provider,
      providerConfig: result.providerConfig,
    };
  }

  /**
   * Get active VoIP provider info
   */
  getActiveProvider(): { provider: string; health: any } {
    const provider = this.voipManager.getActiveProvider();
    return {
      provider: provider.providerType,
      health: provider.isConfigured(),
    };
  }

  /**
   * Get health status of all VoIP providers
   */
  async getProvidersHealth() {
    return this.voipManager.getHealthStatus();
  }

  /**
   * Manually switch VoIP provider
   */
  async switchProvider(providerType: VoipProviderType): Promise<boolean> {
    return this.voipManager.switchProvider(providerType);
  }

  /**
   * Get call rate for a destination
   */
  async getCallRate(phoneNumber: string) {
    return await this.rateCalculatorService.getRate(phoneNumber);
  }

  /**
   * Estimate call cost
   */
  async estimateCallCost(phoneNumber: string, estimatedDurationMinutes: number = 1) {
    const durationSeconds = estimatedDurationMinutes * 60;
    return await this.rateCalculatorService.estimateCallCost(phoneNumber, durationSeconds);
  }
  

  /**
   * Initiate an outbound call
   */
  async initiateCall(dto: InitiateCallDto) {
    const { to, from, userId } = dto;

    try {
      this.logger.log(`User ${userId} initiating call to ${to}`);

      // Check user balance
      const user = await this.usersService.findById(userId);

      // Get rate and estimate cost
      const rate = await this.rateCalculatorService.getRate(to);
      const estimatedCost = rate.estimatedCost || rate.ratePerMinute;

      // Check if user has enough balance for at least 1 minute
      if (user.balance < estimatedCost) {
        throw new BadRequestException('Insufficient balance');
      }

      // Create call record
      const callRecord = this.callRecordRepository.create({
        userId,
        fromNumber: from || 'client',
        toNumber: to,
        direction: CallDirection.OUTBOUND,
        status: CallStatus.INITIATED,
        ratePerMinute: rate.ratePerMinute,
        countryCode: rate.countryCode,
        carrierName: rate.carrierName,
        networkType: rate.networkType,
      });

      await this.callRecordRepository.save(callRecord);

      // For WebRTC calls, we don't need to initiate through Telnyx here
      // The client will handle the WebRTC connection
      // We'll update the call record via webhooks

      this.logger.log(`Call record created: ${callRecord.id}`);

      return {
        callId: callRecord.id,
        rate,
        estimatedCost,
      };
    } catch (error) {
      this.logger.error('Error initiating call:', error);
      throw error;
    }
  }

  /**
   * Handle webhook events from any VoIP provider
   * Supports Voximplant, Twilio, and Telnyx webhooks
   */
  async handleWebhook(providerType: VoipProviderType, rawPayload: any, headers?: Record<string, string>) {
    try {
      // Parse the webhook using the appropriate provider
      const payload = this.voipManager.parseWebhook(providerType, rawPayload, headers);

      this.logger.log(`Webhook event from ${providerType}: ${payload.eventType} for call ${payload.callId}`);

      // Find call record by provider-specific IDs
      let callRecord = await this.findCallRecord(payload);

      // If no call record found, create one (for inbound calls)
      if (!callRecord && payload.status === 'initiated' && payload.direction === 'inbound') {
        callRecord = await this.handleInboundCall(payload);
      }

      if (!callRecord) {
        this.logger.warn(`No call record found for ${payload.callId}`);
        return { success: false, error: 'Call record not found' };
      }

      // Update call record based on status
      await this.updateCallFromWebhook(callRecord, payload);

      return { success: true };
    } catch (error) {
      this.logger.error('Error handling webhook:', error);
      throw error;
    }
  }

  /**
   * Find call record by various provider IDs
   */
  private async findCallRecord(payload: VoipWebhookPayload): Promise<CallRecord | null> {
    // Try to find by the call ID first
    let callRecord = await this.callRecordRepository.findOne({
      where: { providerCallId: payload.callId },
    });

    if (!callRecord && payload.sessionId) {
      callRecord = await this.callRecordRepository.findOne({
        where: { providerSessionId: payload.sessionId },
      });
    }

    // Fallback to legacy Telnyx fields for backward compatibility
    if (!callRecord) {
      callRecord = await this.callRecordRepository.findOne({
        where: [
          { telnyxCallControlId: payload.callId },
          { telnyxCallSessionId: payload.sessionId },
        ],
      });
    }

    return callRecord;
  }

  /**
   * Update call record from webhook payload
   */
  private async updateCallFromWebhook(callRecord: CallRecord, payload: VoipWebhookPayload) {
    // Store provider-specific IDs
    callRecord.providerCallId = payload.callId;
    callRecord.providerSessionId = payload.sessionId;
    callRecord.voipProvider = payload.provider;

    // Update based on status
    switch (payload.status) {
      case 'initiated':
        callRecord.status = CallStatus.INITIATED;
        callRecord.callStartedAt = payload.startTime || new Date();
        break;

      case 'ringing':
        callRecord.status = CallStatus.RINGING;
        break;

      case 'answered':
        callRecord.status = CallStatus.ANSWERED;
        callRecord.callAnsweredAt = payload.answerTime || new Date();
        break;

      case 'completed':
        callRecord.status = CallStatus.COMPLETED;
        callRecord.callEndedAt = payload.endTime || new Date();
        callRecord.durationSeconds = payload.durationSeconds || 0;
        callRecord.hangupCause = payload.hangupCause;

        // Calculate cost and deduct balance
        if (callRecord.durationSeconds > 0) {
          await this.processCallCompletion(callRecord);
        }
        break;

      case 'failed':
      case 'busy':
      case 'no_answer':
      case 'canceled':
        callRecord.status = CallStatus.FAILED;
        callRecord.hangupCause = payload.hangupCause || payload.status;
        break;
    }

    // Store recording URL if available
    if (payload.recordingUrl) {
      callRecord.recordingUrl = payload.recordingUrl;
    }

    await this.callRecordRepository.save(callRecord);
  }

  /**
   * Process call completion - calculate cost and deduct balance
   */
  private async processCallCompletion(callRecord: CallRecord) {
    const cost = this.rateCalculatorService.calculateCost(
      callRecord.durationSeconds,
      callRecord.ratePerMinute || 0.012,
      0,
      6,
    );

    callRecord.cost = cost;
    callRecord.billableSeconds = Math.ceil(callRecord.durationSeconds / 6) * 6;

    // Deduct from user balance if outbound call
    if (callRecord.direction === CallDirection.OUTBOUND && callRecord.userId) {
      try {
        await this.transactionsService.deductBalance(
          callRecord.userId,
          cost,
          `Call to ${callRecord.toNumber} (${Math.floor(callRecord.durationSeconds / 60)}m ${callRecord.durationSeconds % 60}s)`,
          callRecord.id,
        );
        this.logger.log(`Deducted $${cost} from user ${callRecord.userId}`);
      } catch (error) {
        this.logger.error('Error deducting balance:', error);
      }
    }
  }

  private async handleInboundCall(payload: VoipWebhookPayload): Promise<CallRecord> {
    // Create call record for inbound call
    const callRecord = this.callRecordRepository.create({
      providerCallId: payload.callId,
      providerSessionId: payload.sessionId,
      voipProvider: payload.provider,
      fromNumber: payload.from,
      toNumber: payload.to,
      direction: CallDirection.INBOUND,
      status: CallStatus.INITIATED,
      userId: null, // Will be set later if user answers
    });

    await this.callRecordRepository.save(callRecord);
    return callRecord;
  }

  /**
   * Get call history for a user
   */
  async getCallHistory(userId: string, limit: number = 50, offset: number = 0) {
    const [calls, total] = await this.callRecordRepository.findAndCount({
      where: { userId },
      order: { createdAt: 'DESC' },
      take: limit,
      skip: offset,
    });

    return {
      calls: calls.map(call => call.toSafeObject()),
      total,
      limit,
      offset,
    };
  }

  /**
   * Get call statistics for a user
   */
  async getCallStatistics(userId: string) {
    const stats = await this.callRecordRepository
      .createQueryBuilder('call')
      .select('COUNT(*)', 'totalCalls')
      .addSelect('SUM(duration_seconds)', 'totalDuration')
      .addSelect('SUM(cost)', 'totalCost')
      .addSelect('AVG(quality_score)', 'avgQuality')
      .where('call.user_id = :userId', { userId })
      .andWhere('call.status = :status', { status: CallStatus.COMPLETED })
      .getRawOne();

    return {
      totalCalls: parseInt(stats.totalCalls) || 0,
      totalDuration: parseInt(stats.totalDuration) || 0,
      totalCost: parseFloat(stats.totalCost) || 0,
      avgQuality: parseFloat(stats.avgQuality) || 0,
    };
  }
}
