import { ApiProperty } from '@nestjs/swagger';
import { ProjectStatus } from '@prisma/client';
import {
  RELIABILITY_STANDINGS,
  type ReliabilityStanding,
} from '../../hunter-reliability/reliability.calc';
import { INACTIVE_GEM_OUTCOMES } from './resolve-inactive-gem.dto';
import type { InactiveGemOutcome } from './resolve-inactive-gem.dto';

export class InactiveGemProjectDto {
  @ApiProperty() id!: string;
  @ApiProperty() name!: string;
  @ApiProperty() slug!: string;
  @ApiProperty({ enum: ProjectStatus }) status!: ProjectStatus;
  @ApiProperty() primaryTag!: string;
  @ApiProperty() listedAt!: string;
}

export class InactiveGemHunterDto {
  @ApiProperty() id!: string;
  @ApiProperty({ nullable: true, type: String }) username!: string | null;
  @ApiProperty({ nullable: true, type: String }) displayName!: string | null;
  @ApiProperty({ nullable: true, type: String }) avatarUrl!: string | null;
  @ApiProperty({ enum: RELIABILITY_STANDINGS }) standing!: ReliabilityStanding;
  @ApiProperty({ nullable: true, type: Number }) coverage!: number | null;
}

/** A gem members have reported as abandoned, awaiting a moderator. */
export class InactiveGemQueueItemDto {
  @ApiProperty({ type: InactiveGemProjectDto })
  project!: InactiveGemProjectDto;

  @ApiProperty({ type: [InactiveGemHunterDto] })
  hunters!: InactiveGemHunterDto[];

  @ApiProperty() openReports!: number;
  @ApiProperty() firstReportedAt!: string;
  @ApiProperty() lastActivityAt!: string;
  @ApiProperty() daysQuiet!: number;
  @ApiProperty() membersWaiting!: number;
}

export class InactiveGemQueueResponseDto {
  @ApiProperty({ type: [InactiveGemQueueItemDto] })
  data!: InactiveGemQueueItemDto[];

  @ApiProperty() total!: number;
  @ApiProperty() limit!: number;
  @ApiProperty() offset!: number;
}

export class ResolveInactiveGemResponseDto {
  @ApiProperty() ok!: boolean;
  @ApiProperty() projectId!: string;
  @ApiProperty() resolvedCount!: number;
  @ApiProperty({ enum: INACTIVE_GEM_OUTCOMES }) outcome!: InactiveGemOutcome;
}
