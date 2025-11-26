import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';

@Entity('call_rates')
export class CallRate {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'country_code' })
  countryCode: string;

  @Column({ name: 'country_name' })
  countryName: string;

  @Column({ name: 'dial_code' })
  dialCode: string;

  @Column({ name: 'network_type', nullable: true })
  networkType: string; // mobile, landline, premium

  @Column({ name: 'carrier_name', nullable: true })
  carrierName: string; // MTN, Glo, Airtel, 9mobile, etc.

  @Column({ type: 'decimal', precision: 10, scale: 5, name: 'rate_per_minute' })
  ratePerMinute: number;

  @Column({ type: 'decimal', precision: 10, scale: 5, name: 'connection_fee', default: 0 })
  connectionFee: number;

  @Column({ name: 'billing_increment', default: 6 })
  billingIncrement: number; // seconds (e.g., 6 = bill in 6-second increments)

  @Column({ name: 'min_charge_duration', default: 0 })
  minChargeDuration: number; // minimum seconds to charge

  @Column({ default: true, name: 'is_active' })
  isActive: boolean;

  @Column({ name: 'quality_tier', default: 'standard' })
  qualityTier: string; // premium, standard, economy

  @Column({ type: 'json', nullable: true })
  metadata: Record<string, any>;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;

  toSafeObject() {
    return {
      id: this.id,
      countryCode: this.countryCode,
      countryName: this.countryName,
      dialCode: this.dialCode,
      networkType: this.networkType,
      carrierName: this.carrierName,
      ratePerMinute: parseFloat(this.ratePerMinute.toString()),
      connectionFee: parseFloat(this.connectionFee.toString()),
      billingIncrement: this.billingIncrement,
      minChargeDuration: this.minChargeDuration,
      isActive: this.isActive,
      qualityTier: this.qualityTier,
      metadata: this.metadata,
    };
  }
}
