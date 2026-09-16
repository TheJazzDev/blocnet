import { ApiProperty } from '@nestjs/swagger';
import { InviteStatus, ProjectInviteKind } from '@prisma/client';

export class MyInviteProjectDto {
  @ApiProperty() id!: string;
  @ApiProperty() name!: string;
  @ApiProperty() slug!: string;
  @ApiProperty() followersCount!: number;

  @ApiProperty({ description: 'Published updates on the gem, any author.' })
  updatesCount!: number;

  @ApiProperty({
    nullable: true,
    type: String,
    description: 'The newest published update; null when there is none.',
  })
  lastUpdateAt!: string | null;
}

export class MyInviteInviterDto {
  @ApiProperty() id!: string;
  @ApiProperty({ nullable: true, type: String }) username!: string | null;
  @ApiProperty({ nullable: true, type: String }) displayName!: string | null;
}

/** An invite to co-own or take over a gem, as its invited hunter sees it. */
export class MyInviteDto {
  @ApiProperty() id!: string;
  @ApiProperty() projectId!: string;
  @ApiProperty() hunterId!: string;
  @ApiProperty() invitedBy!: string;
  @ApiProperty({ nullable: true, type: String }) note!: string | null;

  @ApiProperty({
    enum: ProjectInviteKind,
    description:
      'co_own: join the gem’s owners. handover: the inviter’s ownership becomes yours on accept.',
  })
  kind!: ProjectInviteKind;

  @ApiProperty({ enum: InviteStatus }) status!: InviteStatus;
  @ApiProperty({ nullable: true, type: String }) reviewedBy!: string | null;
  @ApiProperty({ nullable: true, type: Date }) reviewedAt!: Date | null;
  @ApiProperty() createdAt!: Date;
  @ApiProperty() updatedAt!: Date;
  @ApiProperty({ type: MyInviteProjectDto }) project!: MyInviteProjectDto;
  @ApiProperty({ type: MyInviteInviterDto }) inviter!: MyInviteInviterDto;
}
