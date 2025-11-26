import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { CallRate } from './entities/call-rate.entity';

export interface RateCalculation {
  ratePerMinute: number;
  connectionFee: number;
  estimatedCost: number;
  billingIncrement: number;
  countryCode: string;
  countryName: string;
  carrierName?: string;
  networkType?: string;
}

@Injectable()
export class RateCalculatorService {
  private readonly logger = new Logger(RateCalculatorService.name);

  constructor(
    @InjectRepository(CallRate)
    private callRateRepository: Repository<CallRate>,
  ) {}

  /**
   * Parse and extract country code from phone number
   */
  parsePhoneNumber(phoneNumber: string): {
    countryCode: string;
    dialCode: string;
    nationalNumber: string;
  } {
    // Remove any non-digit characters except +
    let cleaned = phoneNumber.replace(/[^\d+]/g, '');

    // Remove leading + if present
    if (cleaned.startsWith('+')) {
      cleaned = cleaned.substring(1);
    }

    // Nigerian numbers
    if (cleaned.startsWith('234')) {
      return {
        countryCode: 'NG',
        dialCode: '234',
        nationalNumber: cleaned.substring(3),
      };
    }

    // US/Canada
    if (cleaned.startsWith('1') && cleaned.length === 11) {
      return {
        countryCode: 'US',
        dialCode: '1',
        nationalNumber: cleaned.substring(1),
      };
    }

    // UK
    if (cleaned.startsWith('44')) {
      return {
        countryCode: 'GB',
        dialCode: '44',
        nationalNumber: cleaned.substring(2),
      };
    }

    // Ghana
    if (cleaned.startsWith('233')) {
      return {
        countryCode: 'GH',
        dialCode: '233',
        nationalNumber: cleaned.substring(3),
      };
    }

    // Kenya
    if (cleaned.startsWith('254')) {
      return {
        countryCode: 'KE',
        dialCode: '254',
        nationalNumber: cleaned.substring(3),
      };
    }

    // South Africa
    if (cleaned.startsWith('27')) {
      return {
        countryCode: 'ZA',
        dialCode: '27',
        nationalNumber: cleaned.substring(2),
      };
    }

    // Default - try to guess
    const dialCode = cleaned.substring(0, 3);
    return {
      countryCode: 'UNKNOWN',
      dialCode,
      nationalNumber: cleaned.substring(dialCode.length),
    };
  }

  /**
   * Detect Nigerian carrier from phone number
   */
  detectNigerianCarrier(nationalNumber: string): string | null {
    if (!nationalNumber || nationalNumber.length < 3) {
      return null;
    }

    // Remove leading zero if present
    const number = nationalNumber.startsWith('0')
      ? nationalNumber.substring(1)
      : nationalNumber;

    const prefix = number.substring(0, 3);

    // MTN prefixes
    const mtnPrefixes = ['803', '806', '810', '813', '814', '816', '903', '906'];
    if (mtnPrefixes.includes(prefix)) {
      return 'MTN';
    }

    // Glo prefixes
    const gloPrefixes = ['805', '807', '811', '815', '905'];
    if (gloPrefixes.includes(prefix)) {
      return 'Glo';
    }

    // Airtel prefixes
    const airtelPrefixes = ['802', '808', '812', '901', '902', '904', '907'];
    if (airtelPrefixes.includes(prefix)) {
      return 'Airtel';
    }

    // 9mobile prefixes
    const nmobilePrefixes = ['809', '817', '818', '909'];
    if (nmobilePrefixes.includes(prefix)) {
      return '9mobile';
    }

    return null;
  }

  /**
   * Get calling rate for a destination number
   */
  async getRate(phoneNumber: string): Promise<RateCalculation> {
    try {
      const parsed = this.parsePhoneNumber(phoneNumber);
      this.logger.log(`Looking up rate for ${parsed.countryCode} - ${phoneNumber}`);

      // For Nigerian numbers, try to detect carrier
      let carrierName: string | null = null;
      if (parsed.countryCode === 'NG') {
        carrierName = this.detectNigerianCarrier(parsed.nationalNumber);
        this.logger.log(`Detected carrier: ${carrierName}`);
      }

      // Try to find specific rate (carrier-specific for Nigeria)
      let rate = await this.findSpecificRate(
        parsed.countryCode,
        parsed.dialCode,
        carrierName,
      );

      // If no specific rate found, try country-level rate
      if (!rate) {
        rate = await this.findCountryRate(parsed.countryCode, parsed.dialCode);
      }

      // If still no rate found, use default
      if (!rate) {
        this.logger.warn(`No rate found for ${parsed.countryCode}, using default`);
        return this.getDefaultRate(parsed.countryCode);
      }

      return {
        ratePerMinute: parseFloat(rate.ratePerMinute.toString()),
        connectionFee: parseFloat(rate.connectionFee.toString()),
        estimatedCost: parseFloat(rate.ratePerMinute.toString()), // 1 minute estimate
        billingIncrement: rate.billingIncrement,
        countryCode: rate.countryCode,
        countryName: rate.countryName,
        carrierName: rate.carrierName,
        networkType: rate.networkType,
      };
    } catch (error) {
      this.logger.error('Error getting rate:', error);
      throw error;
    }
  }

  /**
   * Find specific rate (carrier-specific)
   */
  private async findSpecificRate(
    countryCode: string,
    dialCode: string,
    carrierName: string | null,
  ): Promise<CallRate | null> {
    if (!carrierName) {
      return null;
    }

    return await this.callRateRepository.findOne({
      where: {
        countryCode,
        dialCode,
        carrierName,
        isActive: true,
      },
    });
  }

  /**
   * Find country-level rate
   */
  private async findCountryRate(
    countryCode: string,
    dialCode: string,
  ): Promise<CallRate | null> {
    return await this.callRateRepository.findOne({
      where: {
        countryCode,
        dialCode,
        isActive: true,
      },
      order: {
        ratePerMinute: 'ASC', // Get cheapest rate
      },
    });
  }

  /**
   * Get default rate for unknown destinations
   */
  private getDefaultRate(countryCode: string): RateCalculation {
    return {
      ratePerMinute: 0.015, // $0.015 per minute default
      connectionFee: 0.005,
      estimatedCost: 0.02,
      billingIncrement: 6,
      countryCode,
      countryName: 'Unknown',
    };
  }

  /**
   * Calculate call cost based on duration
   */
  calculateCost(
    durationSeconds: number,
    ratePerMinute: number,
    connectionFee: number = 0,
    billingIncrement: number = 6,
  ): number {
    // Round up to nearest billing increment
    const billedSeconds = Math.ceil(durationSeconds / billingIncrement) * billingIncrement;

    // Calculate cost
    const minuteCost = (billedSeconds / 60) * ratePerMinute;
    const totalCost = minuteCost + connectionFee;

    return parseFloat(totalCost.toFixed(4));
  }

  /**
   * Estimate call cost for a given duration
   */
  async estimateCallCost(
    phoneNumber: string,
    estimatedDurationSeconds: number,
  ): Promise<{
    rate: RateCalculation;
    estimatedCost: number;
    billedSeconds: number;
  }> {
    const rate = await this.getRate(phoneNumber);

    const billedSeconds =
      Math.ceil(estimatedDurationSeconds / rate.billingIncrement) * rate.billingIncrement;

    const estimatedCost = this.calculateCost(
      estimatedDurationSeconds,
      rate.ratePerMinute,
      rate.connectionFee,
      rate.billingIncrement,
    );

    return {
      rate,
      estimatedCost,
      billedSeconds,
    };
  }

  /**
   * Seed Nigerian calling rates
   */
  async seedNigerianRates(): Promise<void> {
    this.logger.log('Seeding Nigerian calling rates...');

    const nigerianRates = [
      // MTN Nigeria - Most popular carrier
      {
        countryCode: 'NG',
        countryName: 'Nigeria',
        dialCode: '234',
        networkType: 'mobile',
        carrierName: 'MTN',
        ratePerMinute: 0.0089, // Very competitive rate
        connectionFee: 0.003,
        billingIncrement: 6,
        qualityTier: 'premium',
        isActive: true,
      },
      // Glo Nigeria
      {
        countryCode: 'NG',
        countryName: 'Nigeria',
        dialCode: '234',
        networkType: 'mobile',
        carrierName: 'Glo',
        ratePerMinute: 0.0092,
        connectionFee: 0.003,
        billingIncrement: 6,
        qualityTier: 'standard',
        isActive: true,
      },
      // Airtel Nigeria
      {
        countryCode: 'NG',
        countryName: 'Nigeria',
        dialCode: '234',
        networkType: 'mobile',
        carrierName: 'Airtel',
        ratePerMinute: 0.0091,
        connectionFee: 0.003,
        billingIncrement: 6,
        qualityTier: 'premium',
        isActive: true,
      },
      // 9mobile Nigeria
      {
        countryCode: 'NG',
        countryName: 'Nigeria',
        dialCode: '234',
        networkType: 'mobile',
        carrierName: '9mobile',
        ratePerMinute: 0.0095,
        connectionFee: 0.003,
        billingIncrement: 6,
        qualityTier: 'standard',
        isActive: true,
      },
      // Nigeria Landline
      {
        countryCode: 'NG',
        countryName: 'Nigeria',
        dialCode: '234',
        networkType: 'landline',
        carrierName: null,
        ratePerMinute: 0.0075,
        connectionFee: 0.002,
        billingIncrement: 6,
        qualityTier: 'standard',
        isActive: true,
      },
    ];

    for (const rateData of nigerianRates) {
      const existing = await this.callRateRepository.findOne({
        where: {
          countryCode: rateData.countryCode,
          dialCode: rateData.dialCode,
          carrierName: rateData.carrierName,
        },
      });

      if (!existing) {
        const rate = this.callRateRepository.create(rateData);
        await this.callRateRepository.save(rate);
        this.logger.log(`Created rate for ${rateData.carrierName || 'landline'}`);
      }
    }

    // Add rates for other popular destinations from Nigeria
    const otherRates = [
      // USA
      {
        countryCode: 'US',
        countryName: 'United States',
        dialCode: '1',
        networkType: 'mobile',
        ratePerMinute: 0.0125,
        connectionFee: 0.005,
      },
      // UK
      {
        countryCode: 'GB',
        countryName: 'United Kingdom',
        dialCode: '44',
        networkType: 'mobile',
        ratePerMinute: 0.0145,
        connectionFee: 0.005,
      },
      // Ghana
      {
        countryCode: 'GH',
        countryName: 'Ghana',
        dialCode: '233',
        networkType: 'mobile',
        ratePerMinute: 0.0110,
        connectionFee: 0.004,
      },
      // Kenya
      {
        countryCode: 'KE',
        countryName: 'Kenya',
        dialCode: '254',
        networkType: 'mobile',
        ratePerMinute: 0.0115,
        connectionFee: 0.004,
      },
      // South Africa
      {
        countryCode: 'ZA',
        countryName: 'South Africa',
        dialCode: '27',
        networkType: 'mobile',
        ratePerMinute: 0.0105,
        connectionFee: 0.004,
      },
    ];

    for (const rateData of otherRates) {
      const existing = await this.callRateRepository.findOne({
        where: {
          countryCode: rateData.countryCode,
          dialCode: rateData.dialCode,
        },
      });

      if (!existing) {
        const rate = this.callRateRepository.create({
          ...rateData,
          billingIncrement: 6,
          qualityTier: 'standard',
          isActive: true,
        });
        await this.callRateRepository.save(rate);
        this.logger.log(`Created rate for ${rateData.countryName}`);
      }
    }

    this.logger.log('Nigerian calling rates seeded successfully');
  }
}
