import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { AuditLogService } from '../audit-log/audit-log.service';
import type { AuthUser } from '../common/interfaces/auth-user.interface';
import { normalizePagination } from '../common/utils/pagination.util';
import { HunterReliabilityService } from '../hunter-reliability/hunter-reliability.service';
import { daysSince, ownersOf } from '../hunter-reliability/reliability.calc';
import {
  DAY_MS,
  MEMBERS_WAITING_DAYS,
} from '../hunter-reliability/reliability.constants';
import { ReliabilityLoader } from '../hunter-reliability/reliability.loader';
import { PrismaService } from '../prisma/prisma.service';
import type {
  InactiveGemQueueItemDto,
  InactiveGemQueueResponseDto,
  ResolveInactiveGemResponseDto,
} from './dto/inactive-gem-response.dto';
import type { ListInactiveGemsQuery } from './dto/list-inactive-gems.query';
import type { ResolveInactiveGemDto } from './dto/resolve-inactive-gem.dto';

export const INACTIVE_GEMS_RESOLVED_ACTION =
  'project.inactivity_reports_resolved';

/**
 * The moderator side of "report inactive" (F-42).
 *
 * Members' reports were written and moderators notified, but no queue showed
 * them. This is that queue, and the one action a moderator takes from it:
 * closing the open reports with an outcome and a note. It never reassigns the
 * gem — that is a person's decision, made in the console.
 */
@Injectable()
export class InactiveGemsModerationService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auditLog: AuditLogService,
    private readonly reliability: HunterReliabilityService,
    private readonly loader: ReliabilityLoader,
  ) {}

  /** Injected so tests can pin the clock. */
  protected now(): Date {
    return new Date();
  }

  /**
   * Gems with at least one unresolved report, most-reported first.
   *
   * Seven queries whatever the queue length. Paged in memory: the queue is
   * sorted on computed values, and it is short by nature.
   */
  async listQueue(
    query: ListInactiveGemsQuery,
  ): Promise<InactiveGemQueueResponseDto> {
    const { offset, limit } = normalizePagination(query.offset, query.limit);
    const now = this.now();

    const reportRows = await this.prisma.projectInactivityReport.groupBy({
      by: ['projectId'],
      where: { resolvedAt: null },
      _count: { _all: true },
      _min: { createdAt: true },
    });
    if (reportRows.length === 0) {
      return { data: [], total: 0, limit, offset };
    }
    const projectIds = reportRows.map((row) => row.projectId);

    const waitingFrom = new Date(now.getTime() - MEMBERS_WAITING_DAYS * DAY_MS);
    const [projects, lastUpdateAt, waitingRows] = await Promise.all([
      this.prisma.project.findMany({
        relationLoadStrategy: 'join',
        where: { id: { in: projectIds } },
        select: {
          id: true,
          name: true,
          slug: true,
          status: true,
          createdAt: true,
          ownerAdminId: true,
          primaryTag: { select: { name: true } },
          hunters: {
            select: { hunterId: true },
            orderBy: { createdAt: 'asc' },
          },
        },
      }),
      this.loader.loadLastUpdateAt(projectIds),
      this.prisma.projectUpdateRequest.groupBy({
        by: ['projectId'],
        where: {
          projectId: { in: projectIds },
          createdAt: { gte: waitingFrom },
        },
        _count: { _all: true },
      }),
    ]);

    const ownerIds = [...new Set(projects.flatMap((p) => ownersOf(p)))];
    const [profiles, standings] = await Promise.all([
      this.loader.loadProfiles(ownerIds),
      this.reliability.standingsFor(ownerIds),
    ]);
    const profileById = new Map(profiles.map((p) => [p.id, p]));
    const reportsByGem = new Map(reportRows.map((r) => [r.projectId, r]));
    const waitingByGem = new Map(
      waitingRows.map((r) => [r.projectId, r._count._all]),
    );

    const items: InactiveGemQueueItemDto[] = projects.map((project) => {
      const reports = reportsByGem.get(project.id);
      const last = lastUpdateAt.get(project.id) ?? project.createdAt;
      return {
        project: {
          id: project.id,
          name: project.name,
          slug: project.slug,
          status: project.status,
          primaryTag: project.primaryTag.name,
          listedAt: project.createdAt.toISOString(),
        },
        hunters: ownersOf(project).map((id) => {
          const profile = profileById.get(id);
          const summary = standings.get(id);
          return {
            id,
            username: profile?.username ?? null,
            displayName: profile?.displayName ?? null,
            avatarUrl: profile?.avatarUrl ?? null,
            standing: summary?.standing ?? 'new',
            coverage: summary?.coverage ?? null,
          };
        }),
        openReports: reports?._count._all ?? 0,
        firstReportedAt: (reports?._min.createdAt ?? now).toISOString(),
        lastActivityAt: last.toISOString(),
        daysQuiet: daysSince(last, now),
        membersWaiting: waitingByGem.get(project.id) ?? 0,
      };
    });

    items.sort(
      (a, b) =>
        b.openReports - a.openReports ||
        b.daysQuiet - a.daysQuiet ||
        a.firstReportedAt.localeCompare(b.firstReportedAt) ||
        a.project.id.localeCompare(b.project.id),
    );

    return {
      data: items.slice(offset, offset + limit),
      total: items.length,
      limit,
      offset,
    };
  }

  /**
   * Closes every open report on a gem with the moderator's outcome and note,
   * and records it in the audit log. Does not touch the gem or its hunters.
   */
  async resolve(
    actor: AuthUser,
    projectId: string,
    dto: ResolveInactiveGemDto,
  ): Promise<ResolveInactiveGemResponseDto> {
    const project = await this.prisma.project.findUnique({
      where: { id: projectId },
      select: {
        id: true,
        ownerAdminId: true,
        hunters: { select: { hunterId: true } },
      },
    });
    if (!project) throw new NotFoundException('Project not found');

    const note = dto.note.trim();
    if (note.length < 3) {
      throw new BadRequestException(
        'A note of at least 3 characters is required',
      );
    }
    const { count } = await this.prisma.projectInactivityReport.updateMany({
      where: { projectId, resolvedAt: null },
      data: { resolvedAt: this.now(), resolvedBy: actor.id },
    });
    if (count === 0) {
      throw new NotFoundException(
        'This gem has no open inactivity reports to resolve',
      );
    }

    await this.auditLog.create({
      actorId: actor.id,
      action: INACTIVE_GEMS_RESOLVED_ACTION,
      resourceType: 'project',
      resourceId: projectId,
      metadata: {
        outcome: dto.outcome,
        note,
        resolvedCount: count,
        hunterIds: ownersOf(project),
      },
    });

    return { ok: true, projectId, resolvedCount: count, outcome: dto.outcome };
  }

  /** Gems with at least one open report, for the hub's tile. */
  async countOpen(): Promise<number> {
    const rows = await this.prisma.projectInactivityReport.groupBy({
      by: ['projectId'],
      where: { resolvedAt: null },
    });
    return rows.length;
  }
}
