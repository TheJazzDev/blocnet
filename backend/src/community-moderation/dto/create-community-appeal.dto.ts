import { IsNotEmpty, IsString, IsUUID, MaxLength } from 'class-validator';

export class CreateCommunityAppealDto {
  @IsUUID()
  @IsNotEmpty()
  reportId: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(2000)
  reason: string;
}
