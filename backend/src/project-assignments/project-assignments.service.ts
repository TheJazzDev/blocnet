import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InviteStatus, RoleName, UpdateStatus } from '@prisma/client';
import { AuditLogService } from '../audit-log/audit-log.service';
import { AppRole } from '../common/enums/role.enum';
import type { AuthUser } from '../common/interfaces/auth-user.interface';
import { currentLevelSelect, toCurrentLevelDto } from '../levels/level-summary';
import { PrismaService } from '../prisma/prisma.service';
import type { MyInviteDto } from './dto/my-invite-response.dto';

interface InviteProjectStats {
  followersCount: number;
  updatesCount: number;
  lastUpdateAt: Date | null;
}

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

    const invites = await this.prisma.projectHunterInvite.findMany({
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
            currentLevel: {
              select: currentLevelSelect,
            },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
      skip: offset,
      take: Math.min(limit, 100),
    });

    return invites.map((invite) => ({
      ...invite,
      hunter: {
        id: invite.hunter.id,
        email: invite.hunter.email,
        displayName: invite.hunter.displayName,
        currentLevel: toCurrentLevelDto(invite.hunter.currentLevel),
      },
    }));
  }

  async listMyInvites(
    actor: AuthUser,
    status?: InviteStatus,
    offset = 0,
    limit = 30,
  ): Promise<MyInviteDto[]> {
    const invites = await this.prisma.projectHunterInvite.findMany({
      relationLoadStrategy: 'join',
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
        inviter: {
          select: { id: true, username: true, displayName: true },
        },
      },
      orderBy: { createdAt: 'desc' },
      skip: offset,
      take: Math.min(limit, 100),
    });

    const stats = await this.projectStats(invites.map((i) => i.projectId));
    return invites.map((invite) => {
      const stat = stats.get(invite.projectId);
      return {
        ...invite,
        project: {
          ...invite.project,
          followersCount: stat?.followersCount ?? 0,
          updatesCount: stat?.updatesCount ?? 0,
          lastUpdateAt: stat?.lastUpdateAt?.toISOString() ?? null,
        },
      };
    });
  }

  /**
   * Followers, published updates and newest update per gem — what a hunter
   * weighs before co-owning one. Two queries for any number of gems.
   */
  private async projectStats(projectIds: string[]) {
    const stats = new Map<string, InviteProjectStats>();
    const ids = [...new Set(projectIds)];
    if (ids.length === 0) return stats;

    const [follows, updates] = await Promise.all([
      this.prisma.projectFollow.groupBy({
        by: ['projectId'],
        where: { projectId: { in: ids } },
        _count: { _all: true },
      }),
      this.prisma.update.groupBy({
        by: ['projectId'],
        where: { projectId: { in: ids }, status: UpdateStatus.published },
        _count: { _all: true },
        _max: { createdAt: true },
      }),
    ]);
    const statFor = (id: string): InviteProjectStats => {
      const existing = stats.get(id);
      if (existing) return existing;
      const created: InviteProjectStats = {
        followersCount: 0,
        updatesCount: 0,
        lastUpdateAt: null,
      };
      stats.set(id, created);
      return created;
    };
    for (const row of follows) {
      statFor(row.projectId).followersCount = row._count._all;
    }
    for (const row of updates) {
      const stat = statFor(row.projectId);
      stat.updatesCount = row._count._all;
      stat.lastUpdateAt = row._max.createdAt;
    }
    return stats;
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
