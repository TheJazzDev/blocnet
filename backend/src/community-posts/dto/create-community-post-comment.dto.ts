import { IsString, MaxLength, MinLength } from 'class-validator';

export class CreateCommunityPostCommentDto {
  @IsString()
  @MinLength(1)
  @MaxLength(300)
  content!: string;
}
