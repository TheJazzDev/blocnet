import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { UpdateUrgency } from '@prisma/client';
import { Type } from 'class-transformer';
import { IsInt, IsOptional, Max, Min } from 'class-validator';
import { HunterBoardGemDto } from './hunter-reliability-response.dto';

export const GEM_PAGE_UPDATES_DEFAULT_LIMIT = 30;
export const GEM_PAGE_UPDATES_MAX_LIMIT = 100;

export class HunterGemPageQuery {
  @ApiPropertyOptional({
    minimum: 1,
    maximum: GEM_PAGE_UPDATES_MAX_LIMIT,
    default: GEM_PAGE_UPDATES_DEFAULT_LIMIT,
    description: 'How many of the newest updates to return.',
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(GEM_PAGE_UPDATES_MAX_LIMIT)
  limit?: number;
}

/** One published update on the gem's timeline. */
export class HunterGemUpdateDto {
  @ApiProperty() id!: string;
  @ApiProperty() title!: string;

  @ApiProperty({ enum: UpdateUrgency, description: 'The update’s urgency.' })
  priority!: UpdateUrgency;

  @ApiProperty() createdAt!: string;

  @ApiProperty({
    nullable: true,
    type: String,
    description:
      'When the update was last edited; null when it never was. Moderation changes do not count as edits.',
  })
  editedAt!: string | null;

  @ApiProperty({
    description:
      'Updates have no likes yet; always 0, matching the feed (`likesCount`).',
  })
  likesCount!: number;

  @ApiProperty({
    description: 'Comments on the update, counted as the feed counts them.',
  })
  commentsCount!: number;

  @ApiProperty({
    description:
      'Tips sent on this update in the active tipping currency (type tip only), atomic units, as a decimal string.',
  })
  tipsAtomic!: string;

  @ApiProperty({ nullable: true, type: String })
  tipsCurrencyCode!: string | null;

  @ApiProperty({ nullable: true, type: Number })
  tipsCurrencyDecimals!: number | null;
}

/** The hunter's own view of one gem they keep. */
export class HunterGemPageDto {
  @ApiProperty({ type: HunterBoardGemDto })
  gem!: HunterBoardGemDto;

  @ApiProperty({
    type: [HunterGemUpdateDto],
    description: 'Published updates by any author on this gem, newest first.',
  })
  updates!: HunterGemUpdateDto[];

  @ApiProperty({
    nullable: true,
    type: Number,
    description:
      'Days since the latest published update when the gem is quiet; null otherwise, and null for a gem never updated.',
  })
  gapDays!: number | null;
}
