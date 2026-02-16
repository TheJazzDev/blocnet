import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { ProjectProposalStatus } from '@prisma/client';
import { AuditLogService } from '../audit-log/audit-log.service';
import type { AuthUser } from '../common/interfaces/auth-user.interface';
import { ProjectsService } from '../projects/projects.service';
import { PrismaService } from '../prisma/prisma.service';
import { CreateProjectProposalDto } from './dto/create-project-proposal.dto';
import { ReviewProjectProposalDto } from './dto/review-project-proposal.dto';
import { ListProjectProposalsQuery } from './dto/list-project-proposals.query';

@Injectable()
export class ProjectProposalsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly projectsService: ProjectsService,
    private readonly auditLogService: AuditLogService,
  ) {}

  async create(actor: AuthUser, dto: CreateProjectProposalDto) {
    const normalizedName = this.projectsService.normalizeName(dto.name);
    const symbol = this.projectsService.normalizeSymbol(dto.symbol);
    const websiteDomain = this.projectsService.toWebsiteDomain(dto.websiteUrl);

    await this.projectsService.assertNoCanonicalConflict({
      normalizedName,
      symbol,
      websiteDomain,
    });

    const pendingExists = await this.prisma.projectProposal.findFirst({
      where: {
        applicantId: actor.id,
        status: ProjectProposalStatus.pending,
        normalizedName,
      },
      select: { id: true },
    });

    if (pendingExists) {
      throw new BadRequestException(
        'You already have a pending proposal for this project',
      );
    }

    const primaryTag = await this.prisma.primaryTag.findUnique({
      where: { id: dto.primaryTagId },
      select: { id: true },
    });

    if (!primaryTag) {
      throw new BadRequestException('Invalid primaryTagId');
    }

    const proposal = await this.prisma.projectProposal.create({
      data: {
        applicantId: actor.id,
        name: dto.name,
        normalizedName,
        symbol,
        websiteUrl: dto.websiteUrl?.trim(),
        websiteDomain,
        description: dto.description,
        primaryTagId: dto.primaryTagId,
        reason: dto.reason,
      },
    });

    await this.auditLogService.create({
      actorId: actor.id,
      action: 'project_proposal.create',
      resourceType: 'project_proposal',
      resourceId: proposal.id,
      metadata: {
        normalizedName,
        symbol,
        websiteDomain,
      },
    });

    return proposal;
  }

  async listMine(
    userId: string,
    query: ListProjectProposalsQuery,
  ) {
    const offset = query.offset ?? 0;
    const limit = Math.min(query.limit ?? 30, 100);

    return this.prisma.projectProposal.findMany({
      where: {
        applicantId: userId,
        status: query.status,
      },
      orderBy: { createdAt: 'desc' },
      skip: offset,
      take: limit,
    });
  }

  async listAll(query: ListProjectProposalsQuery) {
    const offset = query.offset ?? 0;
    const limit = Math.min(query.limit ?? 30, 100);

    return this.prisma.projectProposal.findMany({
      where: {
        status: query.status,
      },
      include: {
        applicant: {
          select: {
            id: true,
            email: true,
            displayName: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
      skip: offset,
      take: limit,
    });
  }

  async review(
    reviewer: AuthUser,
    proposalId: string,
    dto: ReviewProjectProposalDto,
  ) {
    if (
      dto.status !== ProjectProposalStatus.approved &&
      dto.status !== ProjectProposalStatus.rejected
    ) {
      throw new BadRequestException('Only approved/rejected statuses are allowed');
    }

    const proposal = await this.prisma.projectProposal.findUnique({
      where: { id: proposalId },
    });

    if (!proposal) {
      throw new NotFoundException('Project proposal not found');
    }

    if (proposal.status !== ProjectProposalStatus.pending) {
      throw new BadRequestException('Project proposal has already been reviewed');
    }

    let createdProjectId: string | null = null;

    if (dto.status === ProjectProposalStatus.approved) {
      const project = await this.projectsService.createProjectForUser({
        actorId: reviewer.id,
        ownerUserId: proposal.applicantId,
        dto: {
          name: proposal.name,
          symbol: proposal.symbol ?? undefined,
          websiteUrl: proposal.websiteUrl ?? undefined,
          description: proposal.description,
          primaryTagId: proposal.primaryTagId,
        },
        auditAction: 'project.create.from_proposal',
        auditMetadata: {
          proposalId: proposal.id,
          applicantId: proposal.applicantId,
        },
      });

      createdProjectId = project.id;

      await this.prisma.projectPoster.upsert({
        where: {
          projectId_posterId: {
            projectId: project.id,
            posterId: proposal.applicantId,
          },
        },
        update: {
          assignedBy: reviewer.id,
        },
        create: {
          projectId: project.id,
          posterId: proposal.applicantId,
          assignedBy: reviewer.id,
        },
      });
    }

    const reviewed = await this.prisma.projectProposal.update({
      where: { id: proposal.id },
      data: {
        status: dto.status,
        reviewerId: reviewer.id,
        reviewNote: dto.note,
        reviewedAt: new Date(),
        createdProjectId,
      },
    });

    await this.auditLogService.create({
      actorId: reviewer.id,
      action: 'project_proposal.review',
      resourceType: 'project_proposal',
      resourceId: reviewed.id,
      metadata: {
        status: dto.status,
        applicantId: proposal.applicantId,
        createdProjectId,
      },
    });

    return reviewed;
  }
}
