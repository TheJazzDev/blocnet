import { IsString, Matches } from 'class-validator';

const currencyCodePattern = /^[A-Z0-9]{2,12}$/;

export class SetActiveTipCurrencyDto {
  @IsString()
  @Matches(currencyCodePattern)
  currencyCode!: string;
}
