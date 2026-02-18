import { Injectable } from '@nestjs/common';
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
    const result = await this.prisma.userRole.upsert({
      where: {
        userId_role: {
          userId,
          role: RoleName.admin,
        },
      },
      update: {
        grantedBy: actorId,
      },
      create: {
        userId,
        role: RoleName.admin,
        grantedBy: actorId,
      },
    });

    await this.auditLogService.create({
      actorId,
      action: 'role.promote.admin',
      resourceType: 'user_role',
      resourceId: result.id,
      metadata: { targetUserId: userId, note },
    });

    return result;
  }

  async promoteToHunter(actorId: string, userId: string, note?: string) {
    const result = await this.prisma.userRole.upsert({
      where: {
        userId_role: {
          userId,
          role: RoleName.hunter,
        },
      },
      update: {
        grantedBy: actorId,
      },
      create: {
        userId,
        role: RoleName.hunter,
        grantedBy: actorId,
      },
    });

    await this.auditLogService.create({
      actorId,
      action: 'role.promote.hunter',
      resourceType: 'user_role',
      resourceId: result.id,
      metadata: { targetUserId: userId, note },
    });

    return result;
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
}
