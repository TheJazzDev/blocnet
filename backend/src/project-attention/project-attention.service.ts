import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { NotificationType, RoleName, UpdateStatus } from '@prisma/client';
import { AuditLogService } from '../audit-log/audit-log.service';
import { NotificationsService } from '../notifications/notifications.service';
import { PrismaService } from '../prisma/prisma.service';
import { dayKey, isoWeekKey } from '../common/utils/iso-week.util';
import { ownersOf } from '../hunter-reliability/reliability.calc';
import { ESCALATE_WAITING_AT } from '../hunter-reliability/reliability.constants';
import { waitingAsksWhere } from '../hunter-reliability/reliability.loader';

/**
 * How often one member may nudge one gem.
 *
 * A week. The point of the nudge is to tell a hunter that people are waiting,
 * and a member who can send it daily is not adding information — they are
 * adding noise to the inbox of the person they want to hear from.
 */
export const NUDGE_COOLDOWN_MS = 7 * 24 * 60 * 60 * 1000;

/**
 * Members holding a hunter to account for a gem they cover.
 *
 * Blocnet's promise is that a hunter keeps a gem current, so the product needs
 * a way for members to act when that stops happening. Two actions, and they
 * are deliberately different in kind: asking for an update is a nudge to the
 * hunter, and reporting inactivity is an escalation to a moderator.
 *
 * Both are aggregated rather than per-tap. Thirty-one members asking for an
 * update must reach the hunter as one notification saying thirty-one people are
 * waiting, not as thirty-one notifications — otherwise the feature becomes a
 * way to harass a hunter rather than a way to reach one.
 */
@Injectable()
export class ProjectAttentionService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly notifications: NotificationsService,
    private readonly auditLog: AuditLogService,
  ) {}

  /**
   * Records a member asking for an update, and notifies the hunter at most
   * once per gem per week.
   *
   * Only followers may ask. Following is the standing the action rests on: a
   * member who has not put the gem on their board is not waiting on it.
   */
  async requestUpdate(memberId: string, projectId: string) {
    const project = await this.loadFollowedProject(memberId, projectId);

    const since = new Date(Date.now() - NUDGE_COOLDOWN_MS);
    const mine = await this.prisma.projectUpdateRequest.findFirst({
      where: { projectId, memberId, createdAt: { gte: since } },
      select: { createdAt: true },
    });
    if (mine) {
      throw new BadRequestException(
        'You have already asked for an update on this gem this week',
      );
    }

    await this.prisma.projectUpdateRequest.create({
      data: { projectId, memberId },
    });

    const waiting = await this.countWaiting(projectId);

    const hunterIds = await this.hunterIdsFor(projectId);
    if (hunterIds.length > 0) {
      // One notification per gem per week, enforced by the unique index on
      // (userId, dedupeKey) rather than by a query we could race.
      const week = isoWeekKey(new Date());
      await this.notifications.notifyMany(
        hunterIds.map((userId) => ({
          userId,
          type: NotificationType.project_update_requested,
          title: `Members are waiting on ${project.name}`,
          body:
            waiting === 1
              ? 'One member has asked for an update on this gem.'
              : `${waiting} members have asked for an update on this gem.`,
          projectId,
          deeplink: `/projects/${projectId}`,
          dedupeKey: `project_update_requested:${projectId}:${week}`,
          skipSelfNotify: true,
          actorUserId: memberId,
        })),
      );
    }

    return {
      ok: true,
      membersWaiting: waiting,
      escalatesAtWaiting: ESCALATE_WAITING_AT,
      hunterNotified: hunterIds.length > 0,
    };
  }

  /**
   * Records a standing report that a gem has been abandoned, and raises it to
   * moderators.
   *
   * This does **not** reassign the gem. Taking coverage away from a hunter
   * changes someone's standing on the platform, so it stays a decision a person
   * makes; this makes the case visible and countable.
   */
  async reportInactive(reporterId: string, projectId: string) {
    const project = await this.loadFollowedProject(reporterId, projectId);

    // One standing report per member per gem. Re-reporting is a no-op rather
    // than an error, because the member's intent is already on file and an
    // error would just look broken to them.
    await this.prisma.projectInactivityReport.upsert({
      where: { projectId_reporterId: { projectId, reporterId } },
      create: { projectId, reporterId },
      update: {},
    });

    const openReports = await this.prisma.projectInactivityReport.count({
      where: { projectId, resolvedAt: null },
    });

    const moderatorIds = await this.moderatorIds();
    if (moderatorIds.length > 0) {
      await this.notifications.notifyMany(
        moderatorIds.map((userId) => ({
          userId,
          type: NotificationType.project_reported_inactive,
          title: `${project.name} reported as unmaintained`,
          body:
            openReports === 1
              ? 'One member reports its hunter has gone quiet.'
              : `${openReports} members report its hunter has gone quiet.`,
          projectId,
          deeplink: `/projects/${projectId}`,
          // Re-raise once a day at most while reports keep arriving.
          dedupeKey: `project_reported_inactive:${projectId}:${dayKey(new Date())}`,
        })),
      );
    }

    await this.auditLog.create({
      actorId: reporterId,
      action: 'project.reported_inactive',
      resourceType: 'project',
      resourceId: projectId,
      metadata: { openReports },
    });

    return { ok: true, openReports };
  }

  /** Who is waiting on a gem, for the card that says so. */
  async attentionFor(projectId: string) {
    const [membersWaiting, openReports] = await Promise.all([
      this.countWaiting(projectId),
      this.prisma.projectInactivityReport.count({
        where: { projectId, resolvedAt: null },
      }),
    ]);
    return {
      membersWaiting,
      openReports,
      escalatesAtWaiting: ESCALATE_WAITING_AT,
    };
  }

  /**
   * Members waiting on a gem: asks inside the cooldown made after its latest
   * published update — the same rule the hunter's board uses, so the member
   * and the hunter see one number. Two queries.
   *
   * The per-member cooldown in `requestUpdate` is deliberately not reset by
   * an update: it limits how often one member can nudge, not what counts.
   */
  private async countWaiting(projectId: string): Promise<number> {
    const latest = await this.prisma.update.aggregate({
      where: { projectId, status: UpdateStatus.published },
      _max: { createdAt: true },
    });
    return this.prisma.projectUpdateRequest.count({
      where: waitingAsksWhere(
        projectId,
        latest._max.createdAt ?? null,
        new Date(),
      ),
    });
  }

  private async loadFollowedProject(userId: string, projectId: string) {
    const project = await this.prisma.project.findUnique({
      where: { id: projectId },
      select: { id: true, name: true },
    });
    if (!project) {
      throw new NotFoundException('Project not found');
    }

    const follow = await this.prisma.projectFollow.findUnique({
      where: { projectId_userId: { projectId, userId } },
      select: { id: true },
    });
    if (!follow) {
      throw new ForbiddenException(
        'Follow this gem before asking its hunter for an update',
      );
    }

    return project;
  }

  /**
   * Who keeps this gem: assigned hunters, falling back to the owning admin.
   * The rule itself is `ownersOf`, shared with reliability so the person a
   * nudge reaches is the person whose reliability it counts against.
   */
  private async hunterIdsFor(projectId: string): Promise<string[]> {
    const project = await this.prisma.project.findUnique({
      where: { id: projectId },
      select: { ownerAdminId: true, hunters: { select: { hunterId: true } } },
    });
    return project ? ownersOf(project) : [];
  }

  private async moderatorIds(): Promise<string[]> {
    // community_moderator is the content-moderation role; admin and owner are
    // included because a small platform may have no moderators yet and an
    // unmaintained gem should never reach nobody.
    const rows = await this.prisma.userRole.findMany({
      where: {
        role: {
          in: [RoleName.community_moderator, RoleName.admin, RoleName.owner],
        },
        user: { isDeactivated: false },
      },
      select: { userId: true },
      distinct: ['userId'],
    });
    return rows.map((row) => row.userId);
  }
}

// Kept importable from here for existing callers; the helpers live in common.
export { dayKey, isoWeekKey } from '../common/utils/iso-week.util';
