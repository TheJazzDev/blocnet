import { PostStatus, PostUrgency } from '@prisma/client';
import { IsEnum, IsOptional, IsString, MaxLength } from 'class-validator';

export class UpdatePostDto {
  @IsOptional()
  @IsString()
  @MaxLength(140)
  title?: string;

  @IsOptional()
  @IsString()
  @MaxLength(15000)
  contentMd?: string;

  @IsOptional()
  @IsEnum(PostUrgency)
  urgency?: PostUrgency;

  @IsOptional()
  @IsEnum(PostStatus)
  status?: PostStatus;
}
