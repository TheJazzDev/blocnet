import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsObject, IsOptional, IsString, IsUUID } from 'class-validator';

export class GrantBadgeDto {
  @ApiProperty()
  @IsUUID()
  @IsNotEmpty()
  userId: string;

  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  badgeSlug: string;

  @ApiProperty({ required: false, type: 'object' })
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
