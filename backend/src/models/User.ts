import {
  Table,
  Column,
  Model,
  DataType,
  PrimaryKey,
  Default,
  AllowNull,
  Unique,
  HasMany,
  CreatedAt,
  UpdatedAt
} from 'sequelize-typescript';
import Transaction from './Transaction';
import CallRecord from './CallRecord';

@Table({
  tableName: 'users',
  timestamps: true,
  underscored: true
})
export default class User extends Model {
  @PrimaryKey
  @Default(DataType.UUIDV4)
  @Column(DataType.UUID)
  id!: string;

  @Unique
  @AllowNull(false)
  @Column(DataType.STRING)
  clerkId!: string;

  @Unique
  @AllowNull(false)
  @Column(DataType.STRING)
  email!: string;

  @Column(DataType.STRING)
  phoneNumber?: string;

  @Column(DataType.STRING)
  displayName?: string;

  @Column(DataType.TEXT)
  profileImageUrl?: string;

  @Default(parseFloat(process.env.INITIAL_BALANCE || '10.00'))
  @AllowNull(false)
  @Column(DataType.DECIMAL(10, 2))
  balance!: number;

  @Column(DataType.DATE)
  lastLoginAt?: Date;

  @Default(true)
  @Column(DataType.BOOLEAN)
  isActive!: boolean;

  @CreatedAt
  @Column(DataType.DATE)
  createdAt!: Date;

  @UpdatedAt
  @Column(DataType.DATE)
  updatedAt!: Date;

  @HasMany(() => Transaction)
  transactions?: Transaction[];

  @HasMany(() => CallRecord)
  callRecords?: CallRecord[];
}
