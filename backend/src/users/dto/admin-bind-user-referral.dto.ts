import { Transform } from 'class-transformer';
import { IsString, Length, Matches } from 'class-validator';

export class AdminBindUserReferralDto {
  @IsString()
  @Length(8, 8)
  @Matches(/^[A-Z0-9]{8}$/)
  @Transform(({ value }) =>
    typeof value === 'string' ? value.trim().toUpperCase() : value,
  )
  code!: string;
}
