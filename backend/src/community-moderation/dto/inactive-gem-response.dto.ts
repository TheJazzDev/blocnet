import { ApiProperty } from '@nestjs/swagger';
import { ProjectStatus } from '@prisma/client';
import {
  RELIABILITY_STANDINGS,
  type ReliabilityStanding,
} from '../../hunter-reliability/reliability.calc';
import {
  INACTIVE_GEM_REASONS,
  type InactiveGemReason,
} from '../inactive-gems.waiting';
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

/**
 * A gem awaiting a moderator: members reported it as abandoned, or enough of
 * them are waiting on it (`escalatesAtWaiting`).
 */
export class InactiveGemQueueItemDto {
  @ApiProperty({ type: InactiveGemProjectDto })
  project!: InactiveGemProjectDto;

  @ApiProperty({ type: [InactiveGemHunterDto] })
  hunters!: InactiveGemHunterDto[];

  @ApiProperty({
    enum: INACTIVE_GEM_REASONS,
    isArray: true,
    description:
      'Why the gem is queued: `reports` (open inactivity reports) and/or `waiting` (at least 50 members waiting since its last update and its last resolution).',
  })
  reasons!: InactiveGemReason[];

  @ApiProperty() openReports!: number;

  @ApiProperty({
    description:
      'The earliest open report; for a gem queued only for waiting, the earliest ask in that wait.',
  })
  firstReportedAt!: string;

  @ApiProperty() lastActivityAt!: string;
  @ApiProperty() daysQuiet!: number;

  @ApiProperty({
    description:
      'Asks in the last 7 days made after the gem’s latest published update.',
  })
  membersWaiting!: number;
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
  @ApiProperty({
    description:
      'Reports closed. 0 for a gem queued only because members are waiting.',
  })
  resolvedCount!: number;
  @ApiProperty({ enum: INACTIVE_GEM_OUTCOMES }) outcome!: InactiveGemOutcome;
}
