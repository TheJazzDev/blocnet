import { IsString, MaxLength } from 'class-validator';

export class UpdatePrimaryTagDto {
  @IsString()
  @MaxLength(120)
  name!: string;
}
