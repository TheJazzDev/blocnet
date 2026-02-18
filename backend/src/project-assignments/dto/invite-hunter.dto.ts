import { IsOptional, IsString, MaxLength } from 'class-validator';

export class InviteHunterDto {
  @IsOptional()
  @IsString()
  @MaxLength(500)
  note?: string;
}
