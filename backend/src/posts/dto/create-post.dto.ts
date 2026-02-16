import { PostUrgency } from '@prisma/client';
import { IsEnum, IsString, MaxLength } from 'class-validator';

export class CreatePostDto {
  @IsString()
  @MaxLength(140)
  title!: string;

  @IsString()
  @MaxLength(15000)
  contentMd!: string;

  @IsEnum(PostUrgency)
  urgency!: PostUrgency;
}
