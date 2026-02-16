import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { RoleName } from '@prisma/client';
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
}
