import {
  IsBoolean,
  IsInt,
  IsOptional,
  IsString,
  Matches,
  Max,
  Min,
} from 'class-validator';

const currencyCodePattern = /^[A-Z0-9]{2,12}$/;

export class UpdateTipCurrencyDto {
  @IsOptional()
  @IsString()
  @Matches(currencyCodePattern)
  code?: string;

  @IsOptional()
  @IsString()
  name?: string;

  @IsOptional()
  @IsString()
  symbol?: string;

  @IsOptional()
  @IsBoolean()
  isEnabled?: boolean;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(10000)
  feeBps?: number;

  @IsOptional()
  @IsString()
  minTip?: string;

  @IsOptional()
  @IsString()
  maxTip?: string | null;

  @IsOptional()
  @IsString()
  minFee?: string;

  @IsOptional()
  @IsString()
  maxFee?: string | null;

  @IsOptional()
  @IsBoolean()
  senderPaysFee?: boolean;

  @IsOptional()
  @IsBoolean()
  policyActive?: boolean;
}

