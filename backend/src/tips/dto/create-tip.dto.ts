import {
  IsOptional,
  IsString,
  IsUUID,
  Matches,
  MaxLength,
  MinLength,
  ValidateIf,
} from 'class-validator';

const usernamePattern = /^@?[a-zA-Z0-9_]{3,24}$/;
const currencyCodePattern = /^[A-Z0-9]{2,12}$/;

export class CreateTipDto {
  @IsString()
  @MinLength(1)
  amount!: string;

  @IsOptional()
  @IsString()
  @Matches(currencyCodePattern)
  currencyCode?: string;

  @ValidateIf((value: CreateTipDto) => !value.toUsername)
  @IsUUID()
  toUserId?: string;

  @ValidateIf((value: CreateTipDto) => !value.toUserId)
  @IsString()
  @Matches(usernamePattern, {
    message:
      'toUsername must be a valid username (3-24 letters, numbers, underscores)',
  })
  toUsername?: string;

  @IsOptional()
  @IsString()
  @MinLength(8)
  @MaxLength(128)
  idempotencyKey?: string;

  @IsOptional()
  @IsString()
  @MinLength(2)
  @MaxLength(220)
  note?: string;

  @IsOptional()
  @IsString()
  @MinLength(2)
  @MaxLength(50)
  contextType?: string;

  @IsOptional()
  @IsString()
  @MinLength(1)
  @MaxLength(120)
  contextId?: string;
}

