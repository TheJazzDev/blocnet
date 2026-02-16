import { IsString, MaxLength } from 'class-validator';

export class CreateProjectDto {
  @IsString()
  @MaxLength(120)
  name!: string;

  @IsString()
  @MaxLength(3000)
  description!: string;

  @IsString()
  @MaxLength(120)
  primaryTag!: string;
}
