import {
  IsArray,
  IsEnum,
  IsIn,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  MinLength,
  ValidateIf,
} from 'class-validator';

export type BroadcastTarget = 'all' | 'hunters' | 'users' | 'specific';

export class BroadcastNotificationDto {
  @IsString()
  @MinLength(1)
  @MaxLength(100)
  title!: string;

  @IsString()
  @MinLength(1)
  @MaxLength(500)
  body!: string;

  @IsIn(['all', 'hunters', 'users', 'specific'])
  target!: BroadcastTarget;

  @ValidateIf((o) => o.target === 'specific')
  @IsArray()
  @IsUUID('4', { each: true })
  userIds?: string[];

  @IsOptional()
  @IsArray()
  @IsEnum(['owner', 'admin', 'hunter', 'user'], { each: true })
  roles?: string[];
}
