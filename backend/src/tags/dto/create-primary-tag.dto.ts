import { IsString, MaxLength } from 'class-validator';

export class CreatePrimaryTagDto {
  @IsString()
  @MaxLength(120)
  name!: string;
}
