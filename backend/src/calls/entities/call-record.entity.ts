import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';

export enum CallDirection {
  INBOUND = 'inbound',
  OUTBOUND = 'outbound',
}

export enum CallStatus {
  INITIATED = 'initiated',
  RINGING = 'ringing',
  ANSWERED = 'answered',
  COMPLETED = 'completed',
  FAILED = 'failed',
  BUSY = 'busy',
  NO_ANSWER = 'no_answer',
  CANCELED = 'canceled',
}

@Entity('call_records')
export class CallRecord {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id' })
  userId: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'user_id' })
  user: User;

  // Provider-agnostic fields
  @Column({ name: 'voip_provider', nullable: true })
  voipProvider: string; // 'voximplant', 'twilio', 'telnyx'

  @Column({ name: 'provider_call_id', nullable: true })
  providerCallId: string;

  @Column({ name: 'provider_session_id', nullable: true })
  providerSessionId: string;

  // Legacy Telnyx fields (kept for backward compatibility)
  @Column({ name: 'telnyx_call_control_id', nullable: true })
  telnyxCallControlId: string;

  @Column({ name: 'telnyx_call_session_id', nullable: true })
  telnyxCallSessionId: string;

  @Column({ name: 'telnyx_call_leg_id', nullable: true })
  telnyxCallLegId: string;

  @Column({ name: 'from_number' })
  fromNumber: string;

  @Column({ name: 'to_number' })
  toNumber: string;

  @Column({
    type: 'enum',
    enum: CallDirection,
    default: CallDirection.OUTBOUND,
  })
  direction: CallDirection;

  @Column({
    type: 'enum',
    enum: CallStatus,
    default: CallStatus.INITIATED,
  })
  status: CallStatus;

  @Column({ name: 'duration_seconds', nullable: true })
  durationSeconds: number;

  @Column({ name: 'billable_seconds', nullable: true })
  billableSeconds: number;

  @Column({ type: 'decimal', precision: 10, scale: 4, nullable: true })
  cost: number;

  @Column({ type: 'decimal', precision: 10, scale: 5, name: 'rate_per_minute', nullable: true })
  ratePerMinute: number;

  @Column({ name: 'country_code', nullable: true })
  countryCode: string;

  @Column({ name: 'carrier_name', nullable: true })
  carrierName: string;

  @Column({ name: 'network_type', nullable: true })
  networkType: string;

  @Column({ name: 'call_started_at', nullable: true })
  callStartedAt: Date;

  @Column({ name: 'call_answered_at', nullable: true })
  callAnsweredAt: Date;

  @Column({ name: 'call_ended_at', nullable: true })
  callEndedAt: Date;

  @Column({ name: 'hangup_cause', nullable: true })
  hangupCause: string;

  @Column({ name: 'recording_url', nullable: true })
  recordingUrl: string;

  @Column({ name: 'quality_score', nullable: true })
  qualityScore: number; // 0-100

  @Column({ type: 'json', nullable: true, name: 'quality_metrics' })
  qualityMetrics: Record<string, any>; // jitter, packet loss, latency

  @Column({ type: 'json', nullable: true })
  metadata: Record<string, any>;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;

  toSafeObject() {
    return {
      id: this.id,
      userId: this.userId,
      voipProvider: this.voipProvider,
      providerCallId: this.providerCallId,
      fromNumber: this.fromNumber,
      toNumber: this.toNumber,
      direction: this.direction,
      status: this.status,
      durationSeconds: this.durationSeconds,
      billableSeconds: this.billableSeconds,
      cost: this.cost ? parseFloat(this.cost.toString()) : null,
      ratePerMinute: this.ratePerMinute ? parseFloat(this.ratePerMinute.toString()) : null,
      countryCode: this.countryCode,
      carrierName: this.carrierName,
      networkType: this.networkType,
      callStartedAt: this.callStartedAt,
      callAnsweredAt: this.callAnsweredAt,
      callEndedAt: this.callEndedAt,
      hangupCause: this.hangupCause,
      recordingUrl: this.recordingUrl,
      qualityScore: this.qualityScore,
      qualityMetrics: this.qualityMetrics,
      metadata: this.metadata,
      createdAt: this.createdAt,
    };
  }
}
