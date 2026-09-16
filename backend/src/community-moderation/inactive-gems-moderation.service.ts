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
import { ReliabilityLoader } from '../hunter-reliability/reliability.loader';
import { PrismaService } from '../prisma/prisma.service';
import type {
  InactiveGemQueueItemDto,
  InactiveGemQueueResponseDto,
  ResolveInactiveGemResponseDto,
} from './dto/inactive-gem-response.dto';
import type { ListInactiveGemsQuery } from './dto/list-inactive-gems.query';
import type { ResolveInactiveGemDto } from './dto/resolve-inactive-gem.dto';
import {
  INACTIVE_GEMS_RESOLVED_ACTION,
  loadWaitingFacts,
  type InactiveGemReason,
} from './inactive-gems.waiting';

export { INACTIVE_GEMS_RESOLVED_ACTION } from './inactive-gems.waiting';

/**
 * The moderator side of "report inactive" (F-42), and of the waiting
 * threshold.
 *
 * A gem enters the queue for either of two reasons: members reported it, or
 * `ESCALATE_WAITING_AT` members are waiting on it. The one action a moderator
 * takes here is closing it with an outcome and a note. It never reassigns the
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
   * Gems with an unresolved report or an escalated wait, most-reported first,
   * then most members waiting.
   *
   * Nine queries whatever the queue length. Paged in memory: the queue is
   * sorted on computed values, and it is short by nature.
   */
  async listQueue(
    query: ListInactiveGemsQuery,
  ): Promise<InactiveGemQueueResponseDto> {
    const { offset, limit } = normalizePagination(query.offset, query.limit);
    const now = this.now();

    const reportRows = await this.openReportRows();
    const reportsByGem = new Map(reportRows.map((r) => [r.projectId, r]));
    const waiting = await loadWaitingFacts(this.prisma, this.loader, {
      projectIds: [...reportsByGem.keys()],
      now,
    });
    const projectIds = [
      ...new Set([...reportsByGem.keys(), ...waiting.escalated.keys()]),
    ];
    if (projectIds.length === 0) {
      return { data: [], total: 0, limit, offset };
    }

    const projects = await this.prisma.project.findMany({
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
    });

    const ownerIds = [...new Set(projects.flatMap((p) => ownersOf(p)))];
    const [profiles, standings] = await Promise.all([
      this.loader.loadProfiles(ownerIds),
      this.reliability.standingsFor(ownerIds),
    ]);
    const profileById = new Map(profiles.map((p) => [p.id, p]));

    const items: InactiveGemQueueItemDto[] = projects.map((project) => {
      const reports = reportsByGem.get(project.id);
      const escalation = waiting.escalated.get(project.id);
      const last = waiting.lastUpdateAt.get(project.id) ?? project.createdAt;
      const reasons: InactiveGemReason[] = [];
      if (reports) reasons.push('reports');
      if (escalation) reasons.push('waiting');
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
        reasons,
        openReports: reports?._count._all ?? 0,
        firstReportedAt: (
          reports?._min.createdAt ??
          escalation?.since ??
          now
        ).toISOString(),
        lastActivityAt: last.toISOString(),
        daysQuiet: daysSince(last, now),
        membersWaiting: waiting.waiting.get(project.id) ?? 0,
      };
    });

    items.sort(
      (a, b) =>
        b.openReports - a.openReports ||
        b.membersWaiting - a.membersWaiting ||
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
   * Closes a gem in the queue: every open report gets the moderator's outcome
   * and note, and the resolution is audited. Does not touch the gem, its
   * hunters or the members' asks.
   *
   * A gem queued only for its wait has no reports to close; the audit entry
   * is then the whole resolution, and it is also what stops those asks from
   * escalating the gem again (see `loadWaitingFacts`).
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
    const now = this.now();
    // Read before closing reports; the resolution itself clears the wait.
    const waiting = await loadWaitingFacts(this.prisma, this.loader, {
      projectIds: [],
      now,
      scope: [projectId],
    });
    const { count } = await this.prisma.projectInactivityReport.updateMany({
      where: { projectId, resolvedAt: null },
      data: { resolvedAt: now, resolvedBy: actor.id },
    });

    const reasons: InactiveGemReason[] = [];
    if (count > 0) reasons.push('reports');
    if (waiting.escalated.has(projectId)) reasons.push('waiting');
    if (reasons.length === 0) {
      throw new NotFoundException(
        'This gem is not in the inactive-gems queue: no open reports and too few members waiting',
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
        reasons,
        resolvedCount: count,
        membersWaiting: waiting.escalated.get(projectId)?.waiting ?? null,
        hunterIds: ownersOf(project),
      },
    });

    return { ok: true, projectId, resolvedCount: count, outcome: dto.outcome };
  }

  /** Gems in the queue (reported or escalated), for the hub's tile. */
  async countOpen(): Promise<number> {
    const reportRows = await this.openReportRows();
    const waiting = await loadWaitingFacts(this.prisma, this.loader, {
      projectIds: [],
      now: this.now(),
    });
    return new Set([
      ...reportRows.map((row) => row.projectId),
      ...waiting.escalated.keys(),
    ]).size;
  }

  private openReportRows() {
    return this.prisma.projectInactivityReport.groupBy({
      by: ['projectId'],
      where: { resolvedAt: null },
      _count: { _all: true },
      _min: { createdAt: true },
    });
  }
}
