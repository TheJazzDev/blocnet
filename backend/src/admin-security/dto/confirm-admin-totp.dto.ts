import { IsString, Matches } from 'class-validator';

export class ConfirmAdminTotpDto {
  @IsString()
  @Matches(/^\d{6}$/)
  code!: string;
}
