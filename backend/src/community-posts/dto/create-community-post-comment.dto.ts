import {
  IsString,
  MaxLength,
  MinLength,
  IsOptional,
  IsUUID,
} from 'class-validator';

export class CreateCommunityPostCommentDto {
  @IsString()
  @MinLength(1)
  @MaxLength(300)
  content!: string;

  @IsOptional()
  @IsUUID()
  replyToId?: string;
}
