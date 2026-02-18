import { IsOptional, IsString, MaxLength } from 'class-validator';

export class AssignHunterDto {
  @IsOptional()
  @IsString()
  @MaxLength(500)
  note?: string;
}
