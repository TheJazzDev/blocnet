import { CommunityReactionKind } from '@prisma/client';
import { IsEnum, IsOptional } from 'class-validator';

export class ReactCommunityPostDto {
  @IsOptional()
  @IsEnum(CommunityReactionKind)
  kind?: CommunityReactionKind;
}
