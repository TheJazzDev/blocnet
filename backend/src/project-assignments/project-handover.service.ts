import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import {
  InviteStatus,
  Prisma,
  ProjectInviteKind,
  RoleName,
  type ProjectHunterInvite,
} from '@prisma/client';
import { AuditLogService } from '../audit-log/audit-log.service';
import type { AuthUser } from '../common/interfaces/auth-user.interface';
import { ownersOf } from '../hunter-reliability/reliability.calc';
import { LevelsService } from '../levels/levels.service';
import { PrismaService } from '../prisma/prisma.service';
import { planHandover } from './handover.plan';

type Tx = Prisma.TransactionClient;

const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/**
 * A hunter handing coverage of a gem to another hunter.
 *
 * A handover is a `ProjectHunterInvite` of kind `handover`: the owning hunter
 * sends it, the receiving hunter answers it, and accepting moves ownership in
 * one transaction. Every write that reads or changes who owns the gem first
 * locks the gem's row, so a second handover, a cancel and an accept on the
 * same gem cannot interleave.
 */
@Injectable()
export class ProjectHandoverService {
  private readonly logger = new Logger(ProjectHandoverService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly auditLogService: AuditLogService,
    private readonly levelsService: LevelsService,
  ) {}

  async startHandover(
    actor: AuthUser,
    projectId: string,
    hunterRef: string,
    note?: string,
  ): Promise<ProjectHunterInvite> {
    const recipient = await this.resolveRecipient(hunterRef);
    if (recipient.id === actor.id) {
      throw new BadRequestException('You cannot hand a gem over to yourself');
    }
    if (recipient.isDeactivated) {
      throw new BadRequestException('That account is deactivated');
    }
    if (!recipient.roles.some((row) => row.role === RoleName.hunter)) {
      throw new ForbiddenException('Target user is not a hunter');
    }
    const trimmedNote = note?.trim() || null;

    const invite = await this.prisma.$transaction(async (tx) => {
      const project = await this.lockProject(tx, projectId);
      if (!ownersOf(project).includes(actor.id)) {
        throw new ForbiddenException('Only the gem’s owner can hand it over');
      }

      const pending = await tx.projectHunterInvite.findMany({
        where: {
          projectId,
          status: InviteStatus.pending,
          OR: [
            { kind: ProjectInviteKind.handover },
            { hunterId: recipient.id },
          ],
        },
        select: { kind: true },
      });
      if (pending.some((row) => row.kind === ProjectInviteKind.handover)) {
        throw new ConflictException(
          'This gem already has a handover waiting for an answer',
        );
      }
      if (pending.length > 0) {
        throw new ConflictException(
          'That hunter already has an invite to this gem waiting for an answer',
        );
      }

      // One invite row per gem and hunter: an earlier answered invite is
      // reopened as this handover, as re-inviting does for co-owning.
      return tx.projectHunterInvite.upsert({
        where: { projectId_hunterId: { projectId, hunterId: recipient.id } },
        update: {
          kind: ProjectInviteKind.handover,
          invitedBy: actor.id,
          note: trimmedNote,
          status: InviteStatus.pending,
          reviewedBy: null,
          reviewedAt: null,
        },
        create: {
          projectId,
          hunterId: recipient.id,
          invitedBy: actor.id,
          note: trimmedNote,
          kind: ProjectInviteKind.handover,
        },
      });
    });

    await this.auditLogService.create({
      actorId: actor.id,
      action: 'project.hunter.handover',
      resourceType: 'project_hunter_invite',
      resourceId: invite.id,
      metadata: {
        projectId,
        hunterId: recipient.id,
        note: trimmedNote,
        round: invite.updatedAt.toISOString(),
      },
    });

    return invite;
  }

  async cancelHandover(
    actor: AuthUser,
    projectId: string,
  ): Promise<ProjectHunterInvite> {
    const invite = await this.prisma.$transaction(async (tx) => {
      await this.lockProject(tx, projectId);
      const pending = await tx.projectHunterInvite.findFirst({
        where: {
          projectId,
          kind: ProjectInviteKind.handover,
          status: InviteStatus.pending,
          invitedBy: actor.id,
        },
        select: { id: true },
      });
      if (!pending) {
        throw new NotFoundException('You have no handover waiting on this gem');
      }
      return tx.projectHunterInvite.update({
        where: { id: pending.id },
        data: {
          status: InviteStatus.cancelled,
          reviewedBy: actor.id,
          reviewedAt: new Date(),
        },
      });
    });

    await this.auditLogService.create({
      actorId: actor.id,
      action: 'project.hunter.handover.cancel',
      resourceType: 'project_hunter_invite',
      resourceId: invite.id,
      metadata: { projectId, hunterId: invite.hunterId },
    });

    return invite;
  }

  /**
   * The receiving hunter's answer. Accepting moves ownership (see
   * `planHandover`); declining changes nothing but the invite. Member asks
   * and inactivity reports belong to the gem, so they stay where they are.
   */
  async respond(
    actor: AuthUser,
    invite: Pick<ProjectHunterInvite, 'id' | 'projectId' | 'invitedBy'>,
    status: 'accepted' | 'rejected',
  ): Promise<ProjectHunterInvite> {
    const fromId = invite.invitedBy;
    const reviewedAt = new Date();
    const { updated, ownerAdminMoved } = await this.prisma.$transaction(
      async (tx) => {
        const project = await this.lockProject(tx, invite.projectId);
        const claimed = await tx.projectHunterInvite.updateMany({
          where: {
            id: invite.id,
            kind: ProjectInviteKind.handover,
            status: InviteStatus.pending,
          },
          data: { status, reviewedBy: actor.id, reviewedAt },
        });
        if (claimed.count === 0) {
          throw new ConflictException('This handover is no longer open');
        }

        let moved = false;
        if (status === InviteStatus.accepted) {
          moved = await this.transfer(tx, actor, project, invite);
        }
        const row = await tx.projectHunterInvite.findUniqueOrThrow({
          where: { id: invite.id },
        });
        return { updated: row, ownerAdminMoved: moved };
      },
    );

    const round = reviewedAt.toISOString();
    await this.auditLogService.create({
      actorId: actor.id,
      action: 'project.hunter.invite.respond',
      resourceType: 'project_hunter_invite',
      resourceId: invite.id,
      metadata: {
        projectId: invite.projectId,
        status,
        kind: ProjectInviteKind.handover,
        round,
      },
    });

    if (status === InviteStatus.accepted) {
      await this.auditLogService.create({
        actorId: actor.id,
        action: 'project.ownership.handover',
        resourceType: 'project',
        resourceId: invite.projectId,
        metadata: {
          projectId: invite.projectId,
          inviteId: invite.id,
          fromHunterId: fromId,
          toHunterId: actor.id,
          ownerAdminMoved,
          round,
        },
      });
      if (ownerAdminMoved) {
        // Levels count gems by ownerAdminId.
        await this.refreshLevel(fromId);
        await this.refreshLevel(actor.id);
      }
    }

    return updated;
  }

  /** Returns whether `Project.ownerAdminId` moved. */
  private async transfer(
    tx: Tx,
    actor: AuthUser,
    project: Awaited<ReturnType<ProjectHandoverService['lockProject']>>,
    invite: Pick<ProjectHunterInvite, 'projectId' | 'invitedBy'>,
  ): Promise<boolean> {
    const hunterRole = await tx.userRole.findFirst({
      where: { userId: actor.id, role: RoleName.hunter },
      select: { id: true },
    });
    if (!hunterRole) {
      throw new ForbiddenException('Only a hunter can take over a gem');
    }

    const plan = planHandover(project, invite.invitedBy, actor.id);
    if (!plan) {
      throw new ConflictException(
        'The hunter who sent this handover no longer owns the gem',
      );
    }

    if (plan.deleteRowId) {
      await tx.projectHunter.delete({ where: { id: plan.deleteRowId } });
    }
    if (plan.moveRow) {
      await tx.projectHunter.update({
        where: { id: plan.moveRow.id },
        data: {
          hunterId: actor.id,
          assignedBy: invite.invitedBy,
          createdAt: plan.moveRow.createdAt,
        },
      });
    }
    if (plan.createRow) {
      await tx.projectHunter.create({
        data: {
          projectId: invite.projectId,
          hunterId: actor.id,
          assignedBy: invite.invitedBy,
        },
      });
    }
    if (plan.moveOwnerAdmin) {
      await tx.project.update({
        where: { id: invite.projectId },
        data: { ownerAdminId: actor.id },
      });
    }
    return plan.moveOwnerAdmin;
  }

  /** Locks the gem's row for the transaction and reads who owns it. */
  private async lockProject(tx: Tx, projectId: string) {
    const locked = await tx.$queryRaw<{ id: string }[]>`
      SELECT id FROM "Project" WHERE id = ${projectId}::uuid FOR UPDATE`;
    if (locked.length === 0) throw new NotFoundException('Project not found');
    return tx.project.findUniqueOrThrow({
      where: { id: projectId },
      select: {
        ownerAdminId: true,
        hunters: {
          select: { id: true, hunterId: true, createdAt: true },
          orderBy: { createdAt: 'asc' },
        },
      },
    });
  }

  private async resolveRecipient(ref: string) {
    const value = ref.trim().replace(/^@/, '');
    const select = {
      id: true,
      isDeactivated: true,
      roles: { select: { role: true } },
    } satisfies Prisma.ProfileSelect;
    const profile = UUID_RE.test(value)
      ? await this.prisma.profile.findUnique({ where: { id: value }, select })
      : await this.prisma.profile.findFirst({
          where: { username: { equals: value, mode: 'insensitive' } },
          select,
        });
    if (!profile) throw new NotFoundException('Hunter not found');
    return profile;
  }

  private async refreshLevel(userId: string) {
    try {
      await this.levelsService.updateUserLevel(userId);
    } catch (error) {
      this.logger.warn(
        `Failed to update level after handover: ${error instanceof Error ? error.message : String(error)}`,
      );
    }
  }
}
