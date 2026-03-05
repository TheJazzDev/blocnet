import { IsBoolean, IsEmail, IsOptional, IsString, MaxLength } from 'class-validator';

export class CreateClosedAlphaEmailDto {
  @IsEmail()
  email!: string;

  @IsOptional()
  @IsString()
  @MaxLength(280)
  note?: string;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}
