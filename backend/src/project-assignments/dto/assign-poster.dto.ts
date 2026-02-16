import { IsOptional, IsString, MaxLength } from 'class-validator';

export class AssignPosterDto {
  @IsOptional()
  @IsString()
  @MaxLength(500)
  note?: string;
}
