import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { RoleName } from '@prisma/client';
import { AppRole } from '../common/enums/role.enum';
import { appRoleToRoleName } from '../common/types/role-map';
import { PrismaService } from '../prisma/prisma.service';
import { AuditLogService } from '../audit-log/audit-log.service';

@Injectable()
export class RolesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auditLogService: AuditLogService,
  ) {}

  async promoteToAdmin(actorId: string, userId: string, note?: string) {
    return this.promoteRole(
      actorId,
      userId,
      RoleName.admin,
      'role.promote.admin',
      note,
    );
  }

  async promoteToModerator(actorId: string, userId: string, note?: string) {
    return this.promoteRole(
      actorId,
      userId,
      RoleName.moderator,
      'role.promote.moderator',
      note,
    );
  }

  async promoteToHunter(actorId: string, userId: string, note?: string) {
    return this.promoteRole(
      actorId,
      userId,
      RoleName.hunter,
      'role.promote.hunter',
      note,
    );
  }

  async demoteAdmin(actorId: string, userId: string) {
    return this.demoteRole(
      actorId,
      userId,
      RoleName.admin,
      'role.demote.admin',
    );
  }

  async demoteModerator(actorId: string, userId: string) {
    return this.demoteRole(
      actorId,
      userId,
      RoleName.moderator,
      'role.demote.moderator',
    );
  }

  async demoteHunter(actorId: string, userId: string) {
    return this.demoteRole(
      actorId,
      userId,
      RoleName.hunter,
      'role.demote.hunter',
    );
  }

  async hasAnyRole(userId: string, roles: AppRole[]): Promise<boolean> {
    const roleNames = roles.map((role) => appRoleToRoleName(role));
    const role = await this.prisma.userRole.findFirst({
      where: {
        userId,
        role: {
          in: roleNames,
        },
      },
      select: { id: true },
    });

    return Boolean(role);
  }

  private async promoteRole(
    actorId: string,
    userId: string,
    role: RoleName,
    auditAction: string,
    note?: string,
  ) {
    this.assertNoSelfEscalation(actorId, userId);
    await this.assertProfileExists(userId);

    const result = await this.prisma.userRole.upsert({
      where: {
        userId_role: {
          userId,
          role,
        },
      },
      update: {
        grantedBy: actorId,
      },
      create: {
        userId,
        role,
        grantedBy: actorId,
      },
    });

    await this.auditLogService.create({
      actorId,
      action: auditAction,
      resourceType: 'user_role',
      resourceId: result.id,
      metadata: { targetUserId: userId, role, note },
    });

    return result;
  }

  private async demoteRole(
    actorId: string,
    userId: string,
    role: RoleName,
    auditAction: string,
  ) {
    await this.assertProfileExists(userId);
    await this.assertSelfDemotionSafety(actorId, userId, role);

    const current = await this.prisma.userRole.findUnique({
      where: {
        userId_role: {
          userId,
          role,
        },
      },
      select: { id: true },
    });

    if (!current) {
      return { deleted: false };
    }

    await this.assertNotRemovingLastOwner(role, userId);

    await this.prisma.userRole.delete({ where: { id: current.id } });

    await this.auditLogService.create({
      actorId,
      action: auditAction,
      resourceType: 'user_role',
      resourceId: current.id,
      metadata: { targetUserId: userId, role },
    });

    return { deleted: true };
  }

  private assertNoSelfEscalation(actorId: string, userId: string) {
    if (actorId === userId) {
      throw new ForbiddenException('Self-escalation is not allowed');
    }
  }

  private async assertSelfDemotionSafety(
    actorId: string,
    userId: string,
    roleToRemove: RoleName,
  ) {
    if (actorId !== userId) {
      return;
    }

    const actorRoles = await this.prisma.userRole.findMany({
      where: { userId: actorId },
      select: { role: true },
    });

    const remaining = actorRoles
      .map((row) => row.role)
      .filter((role) => role !== roleToRemove);

    const hasRemainingManagementRole = remaining.some(
      (role) => role === RoleName.owner || role === RoleName.admin,
    );

    if (!hasRemainingManagementRole) {
      throw new ForbiddenException(
        'Self-demotion would remove your last management path',
      );
    }
  }

  private async assertProfileExists(userId: string) {
    const profile = await this.prisma.profile.findUnique({
      where: { id: userId },
      select: { id: true },
    });

    if (!profile) {
      throw new NotFoundException('User not found');
    }
  }

  private async assertNotRemovingLastOwner(role: RoleName, userId: string) {
    if (role !== RoleName.owner) {
      return;
    }

    const ownerCount = await this.prisma.userRole.count({
      where: { role: RoleName.owner },
    });

    if (ownerCount <= 1) {
      throw new ForbiddenException('Cannot remove the last remaining owner');
    }

    const targetIsOwner = await this.prisma.userRole.findUnique({
      where: {
        userId_role: {
          userId,
          role: RoleName.owner,
        },
      },
      select: { id: true },
    });

    if (!targetIsOwner) {
      throw new NotFoundException('Owner role not found for this user');
    }
  }
}
