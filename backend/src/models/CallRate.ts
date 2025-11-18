import {
  Table,
  Column,
  Model,
  DataType,
  PrimaryKey,
  Default,
  AllowNull,
  Unique,
  CreatedAt,
  UpdatedAt
} from 'sequelize-typescript';

@Table({
  tableName: 'call_rates',
  timestamps: true,
  underscored: true
})
export default class CallRate extends Model {
  @PrimaryKey
  @Default(DataType.UUIDV4)
  @Column(DataType.UUID)
  id!: string;

  @Unique
  @AllowNull(false)
  @Column(DataType.STRING(5))
  countryCode!: string;

  @AllowNull(false)
  @Column(DataType.STRING)
  countryName!: string;

  @AllowNull(false)
  @Column(DataType.DECIMAL(10, 4))
  ratePerMinute!: number;

  @Default('USD')
  @Column(DataType.STRING(3))
  currency!: string;

  @Default(true)
  @Column(DataType.BOOLEAN)
  isActive!: boolean;

  @CreatedAt
  @Column(DataType.DATE)
  createdAt!: Date;

  @UpdatedAt
  @Column(DataType.DATE)
  updatedAt!: Date;
}
