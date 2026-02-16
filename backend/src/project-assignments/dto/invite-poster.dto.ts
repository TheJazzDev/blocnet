import { IsOptional, IsString, MaxLength } from 'class-validator';

export class InvitePosterDto {
  @IsOptional()
  @IsString()
  @MaxLength(500)
  note?: string;
}
