import { ApiProperty } from '@nestjs/swagger';
import {
  GEM_STATES,
  RELIABILITY_STANDINGS,
  type GemState,
  type ReliabilityStanding,
} from '../reliability.calc';

export class ReliabilityLevelDto {
  @ApiProperty() id!: string;
  @ApiProperty() slug!: string;
  @ApiProperty() name!: string;
  @ApiProperty() level!: number;
  @ApiProperty() iconUrl!: string;
  @ApiProperty({ nullable: true, type: String }) color!: string | null;
}

/** A hunter's reliability — the score members judge hunters by. */
export class HunterReliabilityDto {
  @ApiProperty() profileId!: string;
  @ApiProperty({ nullable: true, type: String }) username!: string | null;
  @ApiProperty({ nullable: true, type: String }) displayName!: string | null;
  @ApiProperty({ nullable: true, type: String }) avatarUrl!: string | null;
  @ApiProperty({ nullable: true, type: ReliabilityLevelDto })
  level!: ReliabilityLevelDto | null;

  @ApiProperty({ enum: RELIABILITY_STANDINGS })
  standing!: ReliabilityStanding;

  @ApiProperty({
    nullable: true,
    type: Number,
    description:
      'Share (0–1) of owned gems with activity in the last 14 days. Null when the hunter owns none.',
  })
  coverage!: number | null;

  @ApiProperty({
    nullable: true,
    type: Number,
    description:
      'Median days between consecutive published updates on the same gem, last 90 days. Null with fewer than 2 intervals.',
  })
  cadenceDays!: number | null;

  @ApiProperty({
    nullable: true,
    type: Number,
    description:
      'Share (0–1) of gem-weeks of member asks (last 90 days) answered by an update within 7 days. Null when no ask-week is decided yet.',
  })
  response!: number | null;

  @ApiProperty({
    description:
      'Decided ask-weeks (last 90 days) an update answered within 7 days — the numerator of `response`.',
  })
  responseAnswered!: number;

  @ApiProperty({
    description:
      'Decided ask-weeks (last 90 days), answered or missed — the denominator of `response`. Weeks still inside their 7-day window with no update are not counted.',
  })
  responseAsked!: number;

  @ApiProperty() gemsOwned!: number;

  @ApiProperty({
    description: 'Published updates on owned gems, last 30 days.',
  })
  updates30d!: number;

  @ApiProperty() followersTotal!: number;

  @ApiProperty({
    description:
      'Tips received in the active tipping currency, atomic units, as a decimal string.',
  })
  tipsReceivedTotal!: string;

  @ApiProperty({ nullable: true, type: String })
  tipsCurrencyCode!: string | null;

  @ApiProperty({ nullable: true, type: Number })
  tipsCurrencyDecimals!: number | null;

  @ApiProperty({
    description:
      'Members waiting across owned gems: asks in the last 7 days made after each gem’s latest published update. Posting on a gem clears its waiting.',
  })
  membersWaiting!: number;

  @ApiProperty({ description: 'Unresolved inactivity reports on owned gems.' })
  openReports!: number;

  @ApiProperty({
    example: 50,
    description:
      'Members waiting on one gem at which it enters the moderation queue for reassignment. The same value the member sees.',
  })
  escalatesAtWaiting!: number;

  @ApiProperty() computedAt!: string;
}

export class HunterLeaderboardEntryDto extends HunterReliabilityDto {
  @ApiProperty({ description: '1-based position in the full ranking.' })
  rank!: number;
}

export class HunterLeaderboardResponseDto {
  @ApiProperty({ type: [HunterLeaderboardEntryDto] })
  items!: HunterLeaderboardEntryDto[];

  @ApiProperty({ nullable: true, type: String })
  nextCursor!: string | null;
}

export class BoardGemLastUpdateDto {
  @ApiProperty() id!: string;
  @ApiProperty() title!: string;
  @ApiProperty() publishedAt!: string;
}

/** One gem on the hunter's own board. */
export class HunterBoardGemDto {
  @ApiProperty() projectId!: string;
  @ApiProperty() name!: string;

  @ApiProperty({
    nullable: true,
    type: String,
    description: 'Projects have no stored logo yet; always null for now.',
  })
  logoUrl!: string | null;

  @ApiProperty() primaryTag!: string;

  @ApiProperty({
    description:
      'The chain chip: the primary tag name as stored (currently the same value as primaryTag).',
  })
  chain!: string;

  @ApiProperty() followersCount!: number;
  @ApiProperty() listedAt!: string;
  @ApiProperty() lastActivityAt!: string;

  @ApiProperty({ description: 'Published updates on this gem, any author.' })
  updatesCount!: number;

  @ApiProperty({ description: 'True when the gem has no published update.' })
  neverUpdated!: boolean;

  @ApiProperty({ nullable: true, type: BoardGemLastUpdateDto })
  lastUpdate!: BoardGemLastUpdateDto | null;

  @ApiProperty() daysQuiet!: number;
  @ApiProperty({ enum: GEM_STATES }) state!: GemState;
  @ApiProperty({
    description:
      'Asks in the last 7 days made after this gem’s latest published update. A count only — no member names.',
  })
  membersWaiting!: number;

  @ApiProperty() openReports!: number;

  @ApiProperty({
    example: 50,
    description:
      'Members waiting on one gem at which it enters the moderation queue for reassignment. The same value the member sees.',
  })
  escalatesAtWaiting!: number;

  @ApiProperty({ nullable: true, type: String })
  nextDeadlineAt!: string | null;
}

export class HunterBoardResponseDto {
  @ApiProperty({ type: HunterReliabilityDto })
  reliability!: HunterReliabilityDto;

  @ApiProperty({ type: [HunterBoardGemDto] })
  gems!: HunterBoardGemDto[];
}

/** The compact form carried on a gem card. */
export class OwnerReliabilityDto {
  @ApiProperty() profileId!: string;
  @ApiProperty({ enum: RELIABILITY_STANDINGS }) standing!: ReliabilityStanding;
  @ApiProperty({ nullable: true, type: Number }) coverage!: number | null;
}
