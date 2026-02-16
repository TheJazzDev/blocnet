import { IsString, MaxLength } from 'class-validator';

export class CreateSecondaryTagDto {
  @IsString()
  @MaxLength(120)
  name!: string;
}
