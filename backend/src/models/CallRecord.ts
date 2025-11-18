import {
  Table,
  Column,
  Model,
  DataType,
  PrimaryKey,
  Default,
  AllowNull,
  ForeignKey,
  BelongsTo,
  Unique,
  CreatedAt,
  UpdatedAt
} from 'sequelize-typescript';
import User from './User';

@Table({
  tableName: 'call_records',
  timestamps: true,
  underscored: true
})
export default class CallRecord extends Model {
  @PrimaryKey
  @Default(DataType.UUIDV4)
  @Column(DataType.UUID)
  id!: string;

  @ForeignKey(() => User)
  @AllowNull(false)
  @Column(DataType.UUID)
  userId!: string;

  @AllowNull(false)
  @Column(DataType.STRING)
  phoneNumber!: string;

  @Column(DataType.STRING)
  contactName?: string;

  @AllowNull(false)
  @Column(DataType.ENUM('outgoing', 'incoming', 'missed'))
  callType!: 'outgoing' | 'incoming' | 'missed';

  @AllowNull(false)
  @Column(DataType.ENUM('connecting', 'ringing', 'connected', 'ended', 'failed', 'rejected'))
  callStatus!: 'connecting' | 'ringing' | 'connected' | 'ended' | 'failed' | 'rejected';

  @Column(DataType.INTEGER)
  duration?: number;

  @Column(DataType.DECIMAL(10, 4))
  cost?: number;

  @Column(DataType.STRING(5))
  countryCode?: string;

  @Unique
  @Column(DataType.STRING)
  twilioCallSid?: string;

  @Column(DataType.DATE)
  startTime?: Date;

  @Column(DataType.DATE)
  endTime?: Date;

  @Default({})
  @Column(DataType.JSONB)
  metadata?: Record<string, any>;

  @CreatedAt
  @Column(DataType.DATE)
  createdAt!: Date;

  @UpdatedAt
  @Column(DataType.DATE)
  updatedAt!: Date;

  @BelongsTo(() => User)
  user?: User;
}
