import { IsString, MaxLength } from 'class-validator';

export class UpdateSecondaryTagDto {
  @IsString()
  @MaxLength(120)
  name!: string;
}
