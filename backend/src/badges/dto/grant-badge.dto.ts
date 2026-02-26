import { ApiProperty } from '@nestjs/swagger';
import {
  IsNotEmpty,
  IsObject,
  IsOptional,
  IsString,
  IsUUID,
} from 'class-validator';

export class GrantBadgeDto {
  @ApiProperty({ required: false })
  @IsString()
  @IsOptional()
  userId?: string;

  @ApiProperty({ required: false, description: 'User email or user UUID' })
  @IsString()
  @IsOptional()
  userIdentifier?: string;

  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  badgeSlug: string;

  @ApiProperty({ required: false })
  @IsObject()
  @IsOptional()
  metadata?: Record<string, any>;
}

export class SetPrimaryBadgeDto {
  @ApiProperty()
  @IsUUID()
  @IsNotEmpty()
  badgeId: string;
}
