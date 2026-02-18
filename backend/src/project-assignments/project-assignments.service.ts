import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InviteStatus, RoleName } from '@prisma/client';
import { AuditLogService } from '../audit-log/audit-log.service';
import { AppRole } from '../common/enums/role.enum';
import type { AuthUser } from '../common/interfaces/auth-user.interface';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class ProjectAssignmentsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auditLogService: AuditLogService,
  ) {}

  async assignHunter(
    actor: AuthUser,
    projectId: string,
    hunterId: string,
    note?: string,
  ) {
    const project = await this.prisma.project.findUnique({
      where: { id: projectId },
    });

    if (!project) {
      throw new NotFoundException('Project not found');
    }

    const isPlatformOwner = actor.roles.includes(AppRole.OWNER);
    const canManage = isPlatformOwner || project.ownerAdminId === actor.id;

    if (!canManage) {
      throw new ForbiddenException(
        'Only owner or project admin can assign hunters',
      );
    }

    const hunterRole = await this.prisma.userRole.findFirst({
      where: {
        userId: hunterId,
        role: RoleName.hunter,
      },
      select: { id: true },
    });

    if (!hunterRole) {
      throw new ForbiddenException('Target user is not a hunter');
    }

    const assignment = await this.prisma.projectHunter.upsert({
      where: {
        projectId_hunterId: {
          projectId,
          hunterId,
        },
      },
      update: {
        assignedBy: actor.id,
      },
      create: {
        projectId,
        hunterId,
        assignedBy: actor.id,
      },
    });

    await this.auditLogService.create({
      actorId: actor.id,
      action: 'project.hunter.assign',
      resourceType: 'project_hunter',
      resourceId: assignment.id,
      metadata: { projectId, hunterId, note },
    });

    return assignment;
  }

  async inviteHunter(
    actor: AuthUser,
    projectId: string,
    hunterId: string,
    note?: string,
  ) {
    const project = await this.prisma.project.findUnique({
      where: { id: projectId },
    });

    if (!project) {
      throw new NotFoundException('Project not found');
    }

    const isPlatformOwner = actor.roles.includes(AppRole.OWNER);
    const canManage = isPlatformOwner || project.ownerAdminId === actor.id;

    if (!canManage) {
      throw new ForbiddenException(
        'Only owner or project admin can invite hunters',
      );
    }

    const hunterRole = await this.prisma.userRole.findFirst({
      where: {
        userId: hunterId,
        role: RoleName.hunter,
      },
      select: { id: true },
    });

    if (!hunterRole) {
      throw new ForbiddenException('Target user is not a hunter');
    }

    const invite = await this.prisma.projectHunterInvite.upsert({
      where: {
        projectId_hunterId: {
          projectId,
          hunterId,
        },
      },
      update: {
        invitedBy: actor.id,
        note,
        status: InviteStatus.pending,
        reviewedBy: null,
        reviewedAt: null,
      },
      create: {
        projectId,
        hunterId,
        invitedBy: actor.id,
        note,
      },
    });

    await this.auditLogService.create({
      actorId: actor.id,
      action: 'project.hunter.invite',
      resourceType: 'project_hunter_invite',
      resourceId: invite.id,
      metadata: { projectId, hunterId, note },
    });

    return invite;
  }

  async listProjectInvites(
    actor: AuthUser,
    projectId: string,
    status?: InviteStatus,
    offset = 0,
    limit = 30,
  ) {
    const project = await this.prisma.project.findUnique({
      where: { id: projectId },
    });

    if (!project) {
      throw new NotFoundException('Project not found');
    }

    const isPlatformOwner = actor.roles.includes(AppRole.OWNER);
    const canManage = isPlatformOwner || project.ownerAdminId === actor.id;

    if (!canManage) {
      throw new ForbiddenException(
        'Only owner or project admin can view invites',
      );
    }

    return this.prisma.projectHunterInvite.findMany({
      where: {
        projectId,
        status,
      },
      include: {
        hunter: {
          select: {
            id: true,
            email: true,
            displayName: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
      skip: offset,
      take: Math.min(limit, 100),
    });
  }

  async listMyInvites(
    actor: AuthUser,
    status?: InviteStatus,
    offset = 0,
    limit = 30,
  ) {
    return this.prisma.projectHunterInvite.findMany({
      where: {
        hunterId: actor.id,
        status,
      },
      include: {
        project: {
          select: {
            id: true,
            name: true,
            slug: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
      skip: offset,
      take: Math.min(limit, 100),
    });
  }

  async respondToInvite(
    actor: AuthUser,
    inviteId: string,
    status: InviteStatus,
  ) {
    if (status !== InviteStatus.accepted && status !== InviteStatus.rejected) {
      throw new ForbiddenException(
        'Only accepted or rejected status is allowed',
      );
    }

    const invite = await this.prisma.projectHunterInvite.findUnique({
      where: { id: inviteId },
      include: {
        project: {
          select: {
            id: true,
          },
        },
      },
    });

    if (!invite) {
      throw new NotFoundException('Invite not found');
    }

    if (invite.hunterId !== actor.id) {
      throw new ForbiddenException('You can only respond to your own invites');
    }

    const updatedInvite = await this.prisma.projectHunterInvite.update({
      where: { id: invite.id },
      data: {
        status,
        reviewedBy: actor.id,
        reviewedAt: new Date(),
      },
    });

    if (status === InviteStatus.accepted) {
      await this.prisma.projectHunter.upsert({
        where: {
          projectId_hunterId: {
            projectId: invite.projectId,
            hunterId: invite.hunterId,
          },
        },
        update: {
          assignedBy: invite.invitedBy,
        },
        create: {
          projectId: invite.projectId,
          hunterId: invite.hunterId,
          assignedBy: invite.invitedBy,
        },
      });
    }

    await this.auditLogService.create({
      actorId: actor.id,
      action: 'project.hunter.invite.respond',
      resourceType: 'project_hunter_invite',
      resourceId: invite.id,
      metadata: {
        projectId: invite.projectId,
        status,
      },
    });

    return updatedInvite;
  }
}
