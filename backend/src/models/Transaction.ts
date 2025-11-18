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
  CreatedAt,
  UpdatedAt
} from 'sequelize-typescript';
import User from './User';

@Table({
  tableName: 'transactions',
  timestamps: true,
  underscored: true
})
export default class Transaction extends Model {
  @PrimaryKey
  @Default(DataType.UUIDV4)
  @Column(DataType.UUID)
  id!: string;

  @ForeignKey(() => User)
  @AllowNull(false)
  @Column(DataType.UUID)
  userId!: string;

  @AllowNull(false)
  @Column(DataType.ENUM('credit', 'debit'))
  type!: 'credit' | 'debit';

  @AllowNull(false)
  @Column(DataType.DECIMAL(10, 2))
  amount!: number;

  @Column(DataType.TEXT)
  description?: string;

  @Column(DataType.STRING)
  referenceType?: string;

  @Column(DataType.STRING)
  referenceId?: string;

  @Column(DataType.DECIMAL(10, 2))
  balanceBefore?: number;

  @Column(DataType.DECIMAL(10, 2))
  balanceAfter?: number;

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
