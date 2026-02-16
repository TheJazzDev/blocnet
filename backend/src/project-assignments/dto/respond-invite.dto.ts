import { InviteStatus } from '@prisma/client';
import { IsEnum } from 'class-validator';

export class RespondInviteDto {
  @IsEnum(InviteStatus)
  status!: InviteStatus;
}
