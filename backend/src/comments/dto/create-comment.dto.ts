import {
  IsString,
  MaxLength,
  MinLength,
  IsOptional,
  IsUUID,
} from 'class-validator';

export class CreateCommentDto {
  @IsString()
  @MinLength(1)
  @MaxLength(5000)
  content!: string;

  @IsOptional()
  @IsUUID()
  replyToId?: string;
}
