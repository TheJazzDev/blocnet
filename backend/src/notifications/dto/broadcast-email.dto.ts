import {
  IsArray,
  IsIn,
  IsOptional,
  IsString,
  IsUrl,
  IsUUID,
  MaxLength,
  MinLength,
  ValidateIf,
} from 'class-validator';

export type BroadcastEmailTarget = 'all' | 'hunters' | 'users' | 'specific';

export class BroadcastEmailDto {
  @IsString()
  @MinLength(1)
  @MaxLength(140)
  subject!: string;

  @IsString()
  @MinLength(1)
  @MaxLength(6000)
  message!: string;

  @IsIn(['all', 'hunters', 'users', 'specific'])
  target!: BroadcastEmailTarget;

  @ValidateIf((o: { target?: BroadcastEmailTarget }) => o.target === 'specific')
  @IsArray()
  @IsUUID('4', { each: true })
  userIds?: string[];

  @IsOptional()
  @IsString()
  @MaxLength(140)
  previewText?: string;

  @IsOptional()
  @IsString()
  @MaxLength(120)
  fromName?: string;

  @IsOptional()
  @IsString()
  @MaxLength(320)
  fromAddress?: string;

  @IsOptional()
  @IsString()
  @MaxLength(320)
  replyTo?: string;

  @IsOptional()
  @IsString()
  @MaxLength(40)
  ctaLabel?: string;

  @IsOptional()
  @IsUrl({ require_protocol: true })
  @MaxLength(2048)
  ctaUrl?: string;
}
