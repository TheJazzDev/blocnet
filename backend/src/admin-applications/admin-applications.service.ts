import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { ApplicationStatus, ApplicationTargetRole } from '@prisma/client';
import { AuditLogService } from '../audit-log/audit-log.service';
import { PrismaService } from '../prisma/prisma.service';
import { RolesService } from '../roles/roles.service';
import { CreateAdminApplicationDto } from './dto/create-admin-application.dto';
import { ReviewAdminApplicationDto } from './dto/review-admin-application.dto';

@Injectable()
export class AdminApplicationsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly rolesService: RolesService,
    private readonly auditLogService: AuditLogService,
  ) {}

  async create(userId: string, dto: CreateAdminApplicationDto) {
    const existingPending = await this.prisma.adminApplication.findFirst({
      where: {
        userId,
        status: ApplicationStatus.pending,
      },
      select: { id: true },
    });

    if (existingPending) {
      throw new BadRequestException('You already have a pending application');
    }

    const targetRole = dto.targetRole ?? ApplicationTargetRole.admin;

    const record = await this.prisma.adminApplication.create({
      data: {
        userId,
        reason: dto.reason,
        targetRole,
      },
    });

    await this.auditLogService.create({
      actorId: userId,
      action: 'admin_application.create',
      resourceType: 'admin_application',
      resourceId: record.id,
      metadata: { targetRole },
    });

    return record;
  }

  async list() {
    return this.prisma.adminApplication.findMany({
      orderBy: { createdAt: 'desc' },
    });
  }

  async review(
    reviewerId: string,
    id: string,
    dto: ReviewAdminApplicationDto,
  ) {
    if (
      dto.status !== ApplicationStatus.approved &&
      dto.status !== ApplicationStatus.rejected
    ) {
      throw new BadRequestException('Only approved/rejected statuses are allowed');
    }

    const app = await this.prisma.adminApplication.findUnique({ where: { id } });

    if (!app) {
      throw new NotFoundException('Application not found');
    }

    const reviewed = await this.prisma.adminApplication.update({
      where: { id },
      data: {
        status: dto.status,
        reviewedBy: reviewerId,
        reviewedAt: new Date(),
      },
    });

    if (dto.status === ApplicationStatus.approved) {
      if (app.targetRole === ApplicationTargetRole.admin) {
        await this.rolesService.promoteToAdmin(reviewerId, app.userId, 'Application approved');
      }

      if (app.targetRole === ApplicationTargetRole.poster) {
        await this.rolesService.promoteToPoster(reviewerId, app.userId, 'Application approved');
      }
    }

    await this.auditLogService.create({
      actorId: reviewerId,
      action: 'admin_application.review',
      resourceType: 'admin_application',
      resourceId: reviewed.id,
      metadata: { status: dto.status, targetRole: app.targetRole, targetUserId: app.userId },
    });

    return reviewed;
  }
}
