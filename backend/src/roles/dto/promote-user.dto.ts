import { IsOptional, IsString, MaxLength } from 'class-validator';

export class PromoteUserDto {
  @IsOptional()
  @IsString()
  @MaxLength(500)
  note?: string;
}
