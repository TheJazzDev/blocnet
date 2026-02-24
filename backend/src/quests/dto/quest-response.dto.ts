import { ApiProperty } from '@nestjs/swagger';
import { BadgeCategory, QuestStatus, QuestType, QuestVerificationStatus } from '@prisma/client';

export class QuestResponseDto {
  @ApiProperty()
  id: string;

  @ApiProperty()
  slug: string;

  @ApiProperty()
  title: string;

  @ApiProperty()
  description: string;

  @ApiProperty({ enum: QuestType })
  type: QuestType;

  @ApiProperty({ enum: BadgeCategory })
  category: BadgeCategory;

  @ApiProperty()
  rewardPoints: number;

  @ApiProperty({ nullable: true })
  rewardBadgeId?: string | null;

  @ApiProperty({ nullable: true })
  targetUrl?: string | null;

  @ApiProperty({ nullable: true })
  targetAction?: string | null;

  @ApiProperty()
  verificationMethod: string;

  @ApiProperty({ nullable: true })
  requiredProof?: string | null;

  @ApiProperty()
  isActive: boolean;

  @ApiProperty()
  sortOrder: number;

  @ApiProperty({ nullable: true })
  expiresAt?: Date | null;

  @ApiProperty()
  createdAt: Date;
}

export class UserQuestResponseDto {
  @ApiProperty()
  id: string;

  @ApiProperty()
  userId: string;

  @ApiProperty()
  questId: string;

  @ApiProperty({ enum: QuestStatus })
  status: QuestStatus;

  @ApiProperty()
  progress: number;

  @ApiProperty({ nullable: true })
  startedAt?: Date | null;

  @ApiProperty({ nullable: true })
  completedAt?: Date | null;

  @ApiProperty()
  createdAt: Date;

  @ApiProperty({ type: QuestResponseDto })
  quest: QuestResponseDto;
}

export class QuestSubmissionResponseDto {
  @ApiProperty()
  id: string;

  @ApiProperty()
  userQuestId: string;

  @ApiProperty()
  userId: string;

  @ApiProperty({ nullable: true })
  proofUrl?: string | null;

  @ApiProperty({ nullable: true })
  proofText?: string | null;

  @ApiProperty({ nullable: true })
  screenshot?: string | null;

  @ApiProperty({ enum: QuestVerificationStatus })
  verificationStatus: QuestVerificationStatus;

  @ApiProperty({ nullable: true })
  verifiedBy?: string | null;

  @ApiProperty({ nullable: true })
  verifiedAt?: Date | null;

  @ApiProperty({ nullable: true })
  rejectionReason?: string | null;

  @ApiProperty({ nullable: true })
  reviewNotes?: string | null;

  @ApiProperty()
  submittedAt: Date;
}

export class UserQuestsListResponseDto {
  @ApiProperty({ type: [UserQuestResponseDto] })
  quests: UserQuestResponseDto[];

  @ApiProperty()
  totalCount: number;

  @ApiProperty()
  completedCount: number;

  @ApiProperty()
  inProgressCount: number;
}
