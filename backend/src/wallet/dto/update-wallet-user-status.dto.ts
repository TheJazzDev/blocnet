import { IsBoolean } from 'class-validator';

export class UpdateWalletUserStatusDto {
  @IsBoolean()
  disabled!: boolean;
}
