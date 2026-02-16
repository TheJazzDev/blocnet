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

  async assignPoster(
    actor: AuthUser,
    projectId: string,
    posterId: string,
    note?: string,
  ) {
    const project = await this.prisma.project.findUnique({ where: { id: projectId } });

    if (!project) {
      throw new NotFoundException('Project not found');
    }

    const isPlatformOwner = actor.roles.includes(AppRole.OWNER);
    const canManage = isPlatformOwner || project.ownerAdminId === actor.id;

    if (!canManage) {
      throw new ForbiddenException('Only owner or project admin can assign posters');
    }

    const posterRole = await this.prisma.userRole.findFirst({
      where: {
        userId: posterId,
        role: RoleName.poster,
      },
      select: { id: true },
    });

    if (!posterRole) {
      throw new ForbiddenException('Target user is not a poster');
    }

    const assignment = await this.prisma.projectPoster.upsert({
      where: {
        projectId_posterId: {
          projectId,
          posterId,
        },
      },
      update: {
        assignedBy: actor.id,
      },
      create: {
        projectId,
        posterId,
        assignedBy: actor.id,
      },
    });

    await this.auditLogService.create({
      actorId: actor.id,
      action: 'project.poster.assign',
      resourceType: 'project_poster',
      resourceId: assignment.id,
      metadata: { projectId, posterId, note },
    });

    return assignment;
  }

  async invitePoster(
    actor: AuthUser,
    projectId: string,
    posterId: string,
    note?: string,
  ) {
    const project = await this.prisma.project.findUnique({ where: { id: projectId } });

    if (!project) {
      throw new NotFoundException('Project not found');
    }

    const isPlatformOwner = actor.roles.includes(AppRole.OWNER);
    const canManage = isPlatformOwner || project.ownerAdminId === actor.id;

    if (!canManage) {
      throw new ForbiddenException('Only owner or project admin can invite posters');
    }

    const posterRole = await this.prisma.userRole.findFirst({
      where: {
        userId: posterId,
        role: RoleName.poster,
      },
      select: { id: true },
    });

    if (!posterRole) {
      throw new ForbiddenException('Target user is not a poster');
    }

    const invite = await this.prisma.projectPosterInvite.upsert({
      where: {
        projectId_posterId: {
          projectId,
          posterId,
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
        posterId,
        invitedBy: actor.id,
        note,
      },
    });

    await this.auditLogService.create({
      actorId: actor.id,
      action: 'project.poster.invite',
      resourceType: 'project_poster_invite',
      resourceId: invite.id,
      metadata: { projectId, posterId, note },
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
    const project = await this.prisma.project.findUnique({ where: { id: projectId } });

    if (!project) {
      throw new NotFoundException('Project not found');
    }

    const isPlatformOwner = actor.roles.includes(AppRole.OWNER);
    const canManage = isPlatformOwner || project.ownerAdminId === actor.id;

    if (!canManage) {
      throw new ForbiddenException('Only owner or project admin can view invites');
    }

    return this.prisma.projectPosterInvite.findMany({
      where: {
        projectId,
        status,
      },
      include: {
        poster: {
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
    return this.prisma.projectPosterInvite.findMany({
      where: {
        posterId: actor.id,
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
      throw new ForbiddenException('Only accepted or rejected status is allowed');
    }

    const invite = await this.prisma.projectPosterInvite.findUnique({
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

    if (invite.posterId !== actor.id) {
      throw new ForbiddenException('You can only respond to your own invites');
    }

    const updatedInvite = await this.prisma.projectPosterInvite.update({
      where: { id: invite.id },
      data: {
        status,
        reviewedBy: actor.id,
        reviewedAt: new Date(),
      },
    });

    if (status === InviteStatus.accepted) {
      await this.prisma.projectPoster.upsert({
        where: {
          projectId_posterId: {
            projectId: invite.projectId,
            posterId: invite.posterId,
          },
        },
        update: {
          assignedBy: invite.invitedBy,
        },
        create: {
          projectId: invite.projectId,
          posterId: invite.posterId,
          assignedBy: invite.invitedBy,
        },
      });
    }

    await this.auditLogService.create({
      actorId: actor.id,
      action: 'project.poster.invite.respond',
      resourceType: 'project_poster_invite',
      resourceId: invite.id,
      metadata: {
        projectId: invite.projectId,
        status,
      },
    });

    return updatedInvite;
  }
}
