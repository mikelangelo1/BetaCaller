import CallRecord from '../models/CallRecord';
import { CallRecordData } from '../types';
import balanceService from './balance.service';
import twilioService from './twilio.service';
import logger from '../utils/logger';

export class CallService {
  async createCallRecord(data: CallRecordData): Promise<CallRecord> {
    const callRecord = await CallRecord.create(data);
    logger.info(`Call record created: ${callRecord.id}`);
    return callRecord;
  }

  async updateCallRecord(
    callId: string,
    updates: Partial<CallRecordData>
  ): Promise<CallRecord> {
    const callRecord = await CallRecord.findByPk(callId);
    if (!callRecord) {
      throw new Error('Call record not found');
    }

    await callRecord.update(updates);
    logger.info(`Call record updated: ${callId}`);
    return callRecord;
  }

  async endCall(
    callId: string,
    duration: number,
    twilioCallSid?: string
  ): Promise<CallRecord> {
    const callRecord = await CallRecord.findByPk(callId);
    if (!callRecord) {
      throw new Error('Call record not found');
    }

    // Calculate cost
    const rate = await twilioService.getCallRate(callRecord.phoneNumber);
    const cost = twilioService.estimateCallCost(duration, rate);

    // Deduct from balance
    try {
      await balanceService.deductBalance(
        callRecord.userId,
        cost,
        `Call to ${callRecord.phoneNumber}`,
        'call',
        callId
      );
    } catch (error) {
      logger.error('Error deducting call cost:', error);
      // Continue even if deduction fails
    }

    await callRecord.update({
      duration,
      cost,
      callStatus: 'ended',
      endTime: new Date(),
      twilioCallSid
    });

    logger.info(`Call ended: ${callId}, Duration: ${duration}s, Cost: $${cost}`);
    return callRecord;
  }

  async getCallHistory(
    userId: string,
    limit: number = 20,
    offset: number = 0
  ): Promise<{ calls: CallRecord[]; total: number }> {
    const { rows, count } = await CallRecord.findAndCountAll({
      where: { userId },
      order: [['createdAt', 'DESC']],
      limit,
      offset
    });

    return {
      calls: rows,
      total: count
    };
  }

  async getCallById(callId: string): Promise<CallRecord | null> {
    return await CallRecord.findByPk(callId);
  }

  async deleteCallRecord(callId: string, userId: string): Promise<void> {
    const callRecord = await CallRecord.findOne({
      where: { id: callId, userId }
    });

    if (!callRecord) {
      throw new Error('Call record not found');
    }

    await callRecord.destroy();
    logger.info(`Call record deleted: ${callId}`);
  }

  async getCallStatistics(userId: string) {
    const calls = await CallRecord.findAll({
      where: { userId }
    });

    const totalCalls = calls.length;
    const totalDuration = calls.reduce((sum, call) => sum + (call.duration || 0), 0);
    const totalCost = calls.reduce((sum, call) => sum + parseFloat(call.cost?.toString() || '0'), 0);

    const outgoingCalls = calls.filter(c => c.callType === 'outgoing').length;
    const incomingCalls = calls.filter(c => c.callType === 'incoming').length;
    const missedCalls = calls.filter(c => c.callType === 'missed').length;

    return {
      totalCalls,
      totalDuration,
      totalCost: parseFloat(totalCost.toFixed(2)),
      outgoingCalls,
      incomingCalls,
      missedCalls,
      averageDuration: totalCalls > 0 ? Math.round(totalDuration / totalCalls) : 0,
      averageCost: totalCalls > 0 ? parseFloat((totalCost / totalCalls).toFixed(2)) : 0
    };
  }
}

export default new CallService();
