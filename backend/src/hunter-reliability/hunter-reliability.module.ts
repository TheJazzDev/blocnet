import { Module } from '@nestjs/common';
import { PrismaModule } from '../prisma/prisma.module';
import {
  HunterReliabilityController,
  MyHunterBoardController,
} from './hunter-reliability.controller';
import { HunterReliabilityService } from './hunter-reliability.service';
import { ReliabilityLoader } from './reliability.loader';

@Module({
  imports: [PrismaModule],
  controllers: [HunterReliabilityController, MyHunterBoardController],
  providers: [HunterReliabilityService, ReliabilityLoader],
  exports: [HunterReliabilityService, ReliabilityLoader],
})
export class HunterReliabilityModule {}
