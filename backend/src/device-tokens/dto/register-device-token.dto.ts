import { IsIn, IsString, MaxLength } from 'class-validator';

export class RegisterDeviceTokenDto {
  @IsString()
  @MaxLength(4096)
  token!: string;

  @IsString()
  @IsIn(['android', 'ios', 'web'])
  platform!: string;
}
