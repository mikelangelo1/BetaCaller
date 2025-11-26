import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ConfigModule } from '@nestjs/config';
import { ScheduleModule } from '@nestjs/schedule';
import { CallRecord } from './entities/call-record.entity';
import { CallRate } from './entities/call-rate.entity';
import { CallsController } from './calls.controller';
import { CallsService } from './calls.service';
import { RateCalculatorService } from './rate-calculator.service';
import { UsersModule } from '../users/users.module';

// VoIP Provider imports
import {
  VoximplantProvider,
  TwilioProvider,
  TelnyxProvider,
  VoipProviderManager,
} from './providers';

// Config imports
import telnyxConfig from '../config/telnyx.config';
import twilioConfig from '../config/twilio.config';
import voximplantConfig from '../config/voximplant.config';
import voipConfig from '../config/voip.config';

@Module({
  imports: [
    TypeOrmModule.forFeature([CallRecord, CallRate]),
    ConfigModule.forFeature(telnyxConfig),
    ConfigModule.forFeature(twilioConfig),
    ConfigModule.forFeature(voximplantConfig),
    ConfigModule.forFeature(voipConfig),
    ScheduleModule.forRoot(),
    UsersModule,
  ],
  controllers: [CallsController],
  providers: [
    // VoIP Providers
    VoximplantProvider,
    TwilioProvider,
    TelnyxProvider,
    VoipProviderManager,
    // Services
    CallsService,
    RateCalculatorService,
  ],
  exports: [
    CallsService,
    RateCalculatorService,
    VoipProviderManager,
    VoximplantProvider,
    TwilioProvider,
    TelnyxProvider,
  ],
})
export class CallsModule {}
