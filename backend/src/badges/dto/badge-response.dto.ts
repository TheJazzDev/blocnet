import { ApiProperty } from '@nestjs/swagger';
import { BadgeCategory, BadgeRarity } from '@prisma/client';

export class BadgeResponseDto {
  @ApiProperty()
  id: string;

  @ApiProperty()
  slug: string;

  @ApiProperty()
  name: string;

  @ApiProperty()
  description: string;

  @ApiProperty()
  imageUrl: string;

  @ApiProperty({ enum: BadgeCategory })
  category: BadgeCategory;

  @ApiProperty({ enum: BadgeRarity })
  rarity: BadgeRarity;

  @ApiProperty()
  pointsRequirement: number;

  @ApiProperty()
  isActive: boolean;

  @ApiProperty()
  sortOrder: number;

  @ApiProperty()
  createdAt: Date;
}

export class UserBadgeResponseDto {
  @ApiProperty()
  id: string;

  @ApiProperty()
  userId: string;

  @ApiProperty()
  badgeId: string;

  @ApiProperty()
  earnedAt: Date;

  @ApiProperty({ nullable: true })
  grantedBy?: string;

  @ApiProperty({ type: BadgeResponseDto })
  badge: BadgeResponseDto;
}

export class UserBadgesResponseDto {
  @ApiProperty({ type: [UserBadgeResponseDto] })
  badges: UserBadgeResponseDto[];

  @ApiProperty()
  totalCount: number;

  @ApiProperty({ type: BadgeResponseDto, nullable: true })
  primaryBadge?: BadgeResponseDto | null;
}
