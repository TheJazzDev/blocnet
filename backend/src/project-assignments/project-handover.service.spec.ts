import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { ReliabilityLoader } from '../hunter-reliability/reliability.loader';
import { ownersOf } from '../hunter-reliability/reliability.calc';
import { planHandover } from './handover.plan';
import { createFakePrisma, type FakeState } from './handover-prisma.fake';
import { ProjectAssignmentsService } from './project-assignments.service';
import { ProjectHandoverService } from './project-handover.service';

const FROM = '11111111-1111-4111-8111-111111111111';
const TO = '22222222-2222-4222-8222-222222222222';
const ADMIN = '33333333-3333-4333-8333-333333333333';
const PLAIN = '44444444-4444-4444-8444-444444444444';
const GONE = '55555555-5555-4555-8555-555555555555';
const GEM = '99999999-9999-4999-8999-999999999999';

const user = (id: string, roles: string[] = ['user', 'hunter']) =>
  ({ id, email: `${id}@x`, roles }) as any;

function setup(opts: { fromHasRow?: boolean; ownerAdminId?: string } = {}) {
  const state: FakeState = {
    profiles: [
      {
        id: FROM,
        username: 'abtoonzz',
        displayName: 'Ab',
        isDeactivated: false,
        roles: ['user', 'hunter'],
      },
      {
        id: TO,
        username: 'Kemi',
        displayName: 'Kemi',
        isDeactivated: false,
        roles: ['user', 'hunter'],
      },
      {
        id: ADMIN,
        username: 'root',
        displayName: null,
        isDeactivated: false,
        roles: ['user', 'admin'],
      },
      {
        id: PLAIN,
        username: 'plain',
        displayName: null,
        isDeactivated: false,
        roles: ['user'],
      },
      {
        id: GONE,
        username: 'gone',
        displayName: null,
        isDeactivated: true,
        roles: ['user', 'hunter'],
      },
    ],
    projects: [
      { id: GEM, name: 'Halo Points', ownerAdminId: opts.ownerAdminId ?? FROM },
    ],
    hunters:
      opts.fromHasRow === false
        ? []
        : [
            {
              id: 'ph-from',
              projectId: GEM,
              hunterId: FROM,
              assignedBy: ADMIN,
              createdAt: new Date('2026-02-01T00:00:00Z'),
            },
          ],
    invites: [],
  };
  const prisma = createFakePrisma(state);
  const audit = { create: jest.fn().mockResolvedValue({}) };
  const levels = { updateUserLevel: jest.fn().mockResolvedValue({}) };
  const handover = new ProjectHandoverService(
    prisma,
    audit as any,
    levels as any,
  );
  const assignments = new ProjectAssignmentsService(
    prisma,
    audit as any,
    handover,
  );
  const owners = () =>
    ownersOf({
      ownerAdminId: state.projects[0].ownerAdminId,
      hunters: state.hunters
        .filter((row) => row.projectId === GEM)
        .sort((a, b) => a.createdAt.getTime() - b.createdAt.getTime()),
    });
  return { state, prisma, audit, levels, handover, assignments, owners };
}

const actions = (audit: { create: jest.Mock }) =>
  audit.create.mock.calls.map((call) => call[0].action);

describe('ProjectHandoverService', () => {
  describe('startHandover', () => {
    it('creates a pending handover by username and audits it', async () => {
      const { handover, audit, state } = setup();
      const invite = await handover.startHandover(
        user(FROM),
        GEM,
        '@kemi',
        ' over to you ',
      );

      expect(invite).toMatchObject({
        projectId: GEM,
        hunterId: TO,
        invitedBy: FROM,
        kind: 'handover',
        status: 'pending',
        note: 'over to you',
      });
      expect(state.invites).toHaveLength(1);
      expect(audit.create).toHaveBeenCalledWith(
        expect.objectContaining({
          action: 'project.hunter.handover',
          resourceId: invite.id,
          metadata: expect.objectContaining({ projectId: GEM, hunterId: TO }),
        }),
      );
    });

    it('accepts a profile id', async () => {
      const { handover } = setup();
      await expect(
        handover.startHandover(user(FROM), GEM, TO),
      ).resolves.toMatchObject({ hunterId: TO });
    });

    it('lets an owner through ownerAdminId hand over a gem with no hunters', async () => {
      const { handover } = setup({ fromHasRow: false });
      await expect(
        handover.startHandover(user(FROM), GEM, 'kemi'),
      ).resolves.toMatchObject({ kind: 'handover' });
    });

    it('refuses a caller who does not own the gem', async () => {
      const { handover, state } = setup();
      await expect(
        handover.startHandover(user(TO), GEM, 'abtoonzz'),
      ).rejects.toBeInstanceOf(ForbiddenException);
      // ownerAdminId alone does not count once hunters are assigned.
      const admin = setup({ ownerAdminId: ADMIN });
      await expect(
        admin.handover.startHandover(user(ADMIN, ['admin']), GEM, 'kemi'),
      ).rejects.toBeInstanceOf(ForbiddenException);
      expect(state.invites).toHaveLength(0);
    });

    it('refuses a recipient who is not a hunter', async () => {
      const { handover } = setup();
      await expect(
        handover.startHandover(user(FROM), GEM, 'plain'),
      ).rejects.toBeInstanceOf(ForbiddenException);
    });

    it('refuses the caller themself and a deactivated account', async () => {
      const { handover } = setup();
      await expect(
        handover.startHandover(user(FROM), GEM, 'abtoonzz'),
      ).rejects.toBeInstanceOf(BadRequestException);
      await expect(
        handover.startHandover(user(FROM), GEM, 'gone'),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('404s for an unknown hunter or gem', async () => {
      const { handover } = setup();
      await expect(
        handover.startHandover(user(FROM), GEM, 'nobody'),
      ).rejects.toBeInstanceOf(NotFoundException);
      await expect(
        handover.startHandover(
          user(FROM),
          '00000000-0000-4000-8000-000000000000',
          'kemi',
        ),
      ).rejects.toBeInstanceOf(NotFoundException);
    });

    it('allows one pending handover per gem', async () => {
      const { handover, state } = setup();
      state.profiles.push({
        id: ADMIN + 'x',
        username: 'third',
        displayName: null,
        isDeactivated: false,
        roles: ['hunter'],
      });
      await handover.startHandover(user(FROM), GEM, 'kemi');
      await expect(
        handover.startHandover(user(FROM), GEM, 'third'),
      ).rejects.toBeInstanceOf(ConflictException);
      await expect(
        handover.startHandover(user(FROM), GEM, 'kemi'),
      ).rejects.toBeInstanceOf(ConflictException);
    });

    it('will not overwrite a pending co-own invite', async () => {
      const { handover, state } = setup();
      state.invites.push({
        id: 'co',
        projectId: GEM,
        hunterId: TO,
        invitedBy: ADMIN,
        note: null,
        kind: 'co_own',
        status: 'pending',
        reviewedBy: null,
        reviewedAt: null,
        createdAt: new Date(),
        updatedAt: new Date(),
      });
      await expect(
        handover.startHandover(user(FROM), GEM, 'kemi'),
      ).rejects.toBeInstanceOf(ConflictException);
    });

    it('reopens an answered invite row for the same hunter', async () => {
      const { handover, assignments, state } = setup();
      const first = await handover.startHandover(user(FROM), GEM, 'kemi');
      await assignments.respondToInvite(user(TO), first.id, 'rejected' as any);

      const again = await handover.startHandover(user(FROM), GEM, 'kemi');
      expect(again.id).toBe(first.id);
      expect(again).toMatchObject({ status: 'pending', reviewedAt: null });
      expect(state.invites).toHaveLength(1);
    });
  });

  describe('cancelHandover', () => {
    it('cancels the caller’s pending handover', async () => {
      const { handover, audit } = setup();
      const invite = await handover.startHandover(user(FROM), GEM, 'kemi');
      const cancelled = await handover.cancelHandover(user(FROM), GEM);
      expect(cancelled).toMatchObject({ id: invite.id, status: 'cancelled' });
      expect(actions(audit)).toContain('project.hunter.handover.cancel');
    });

    it('404s when the caller has nothing pending', async () => {
      const { handover } = setup();
      await handover.startHandover(user(FROM), GEM, 'kemi');
      await expect(
        handover.cancelHandover(user(TO), GEM),
      ).rejects.toBeInstanceOf(NotFoundException);
    });

    it('leaves nothing to accept', async () => {
      const { handover, assignments, owners } = setup();
      const invite = await handover.startHandover(user(FROM), GEM, 'kemi');
      await handover.cancelHandover(user(FROM), GEM);
      await expect(
        assignments.respondToInvite(user(TO), invite.id, 'accepted' as any),
      ).rejects.toBeInstanceOf(ConflictException);
      expect(owners()).toEqual([FROM]);
    });
  });

  describe('responding', () => {
    it('accepting moves ownership, and the board follows', async () => {
      const { handover, assignments, audit, levels, state, prisma, owners } =
        setup();
      const invite = await handover.startHandover(user(FROM), GEM, 'kemi');

      const result = await assignments.respondToInvite(
        user(TO),
        invite.id,
        'accepted' as any,
      );

      expect(result).toMatchObject({ status: 'accepted', reviewedBy: TO });
      expect(owners()).toEqual([TO]);
      expect(state.projects[0].ownerAdminId).toBe(TO);
      // Same slot: the row was re-pointed, not recreated.
      expect(state.hunters).toEqual([
        expect.objectContaining({
          id: 'ph-from',
          hunterId: TO,
          assignedBy: FROM,
        }),
      ]);

      const loader = new ReliabilityLoader(prisma);
      const gems = await loader.loadGems([TO]);
      expect(gems[0].ownerIds).toEqual([TO]);

      expect(actions(audit)).toEqual([
        'project.hunter.handover',
        'project.hunter.invite.respond',
        'project.ownership.handover',
      ]);
      expect(audit.create.mock.calls[2][0].metadata).toMatchObject({
        fromHunterId: FROM,
        toHunterId: TO,
        ownerAdminMoved: true,
      });
      expect(levels.updateUserLevel).toHaveBeenCalledWith(FROM);
      expect(levels.updateUserLevel).toHaveBeenCalledWith(TO);
    });

    it('gives a gem owned only through ownerAdminId its first hunter row', async () => {
      const { handover, assignments, state, owners } = setup({
        fromHasRow: false,
      });
      const invite = await handover.startHandover(user(FROM), GEM, 'kemi');
      await assignments.respondToInvite(user(TO), invite.id, 'accepted' as any);

      expect(owners()).toEqual([TO]);
      expect(state.hunters).toHaveLength(1);
      expect(state.projects[0].ownerAdminId).toBe(TO);
    });

    it('leaves an admin’s ownerAdminId alone', async () => {
      const { handover, assignments, state, owners, levels } = setup({
        ownerAdminId: ADMIN,
      });
      const invite = await handover.startHandover(user(FROM), GEM, 'kemi');
      await assignments.respondToInvite(user(TO), invite.id, 'accepted' as any);

      expect(owners()).toEqual([TO]);
      expect(state.projects[0].ownerAdminId).toBe(ADMIN);
      expect(levels.updateUserLevel).not.toHaveBeenCalled();
    });

    it('a co-owner receiving it keeps the earlier slot and one row', async () => {
      const { handover, assignments, state, owners } = setup();
      state.hunters.push({
        id: 'ph-to',
        projectId: GEM,
        hunterId: TO,
        assignedBy: ADMIN,
        createdAt: new Date('2026-01-01T00:00:00Z'),
      });
      const invite = await handover.startHandover(user(FROM), GEM, 'kemi');
      await assignments.respondToInvite(user(TO), invite.id, 'accepted' as any);

      expect(owners()).toEqual([TO]);
      expect(state.hunters).toHaveLength(1);
      expect(state.hunters[0].createdAt).toEqual(
        new Date('2026-01-01T00:00:00Z'),
      );
    });

    it('refuses to transfer when the sender no longer owns the gem', async () => {
      const { handover, assignments, state, owners } = setup();
      const invite = await handover.startHandover(user(FROM), GEM, 'kemi');
      state.hunters[0].hunterId = ADMIN; // reassigned in the meantime
      await expect(
        assignments.respondToInvite(user(TO), invite.id, 'accepted' as any),
      ).rejects.toBeInstanceOf(ConflictException);
      expect(owners()).toEqual([ADMIN]);
    });

    it('cannot be answered twice', async () => {
      const { handover, assignments } = setup();
      const invite = await handover.startHandover(user(FROM), GEM, 'kemi');
      await assignments.respondToInvite(user(TO), invite.id, 'accepted' as any);
      await expect(
        assignments.respondToInvite(user(TO), invite.id, 'accepted' as any),
      ).rejects.toBeInstanceOf(ConflictException);
    });

    it('only the invited hunter can answer', async () => {
      const { handover, assignments } = setup();
      const invite = await handover.startHandover(user(FROM), GEM, 'kemi');
      await expect(
        assignments.respondToInvite(user(FROM), invite.id, 'accepted' as any),
      ).rejects.toBeInstanceOf(ForbiddenException);
    });

    it('declining leaves ownership unchanged', async () => {
      const { handover, assignments, audit, state, owners } = setup();
      const invite = await handover.startHandover(user(FROM), GEM, 'kemi');
      const result = await assignments.respondToInvite(
        user(TO),
        invite.id,
        'rejected' as any,
      );

      expect(result.status).toBe('rejected');
      expect(owners()).toEqual([FROM]);
      expect(state.projects[0].ownerAdminId).toBe(FROM);
      expect(actions(audit)).toEqual([
        'project.hunter.handover',
        'project.hunter.invite.respond',
      ]);
      expect(audit.create.mock.calls[1][0].metadata).toMatchObject({
        status: 'rejected',
        kind: 'handover',
      });
    });

    it('co-own invites still add the hunter beside the owners', async () => {
      const { assignments, state, owners, audit } = setup();
      state.invites.push({
        id: 'co',
        projectId: GEM,
        hunterId: TO,
        invitedBy: ADMIN,
        note: null,
        kind: 'co_own',
        status: 'pending',
        reviewedBy: null,
        reviewedAt: null,
        createdAt: new Date(),
        updatedAt: new Date(),
      });
      const upsert = jest.fn().mockResolvedValue({});
      (assignments as any).prisma.projectHunter.upsert = upsert;

      await assignments.respondToInvite(user(TO), 'co', 'accepted' as any);

      expect(upsert).toHaveBeenCalledWith(
        expect.objectContaining({
          create: { projectId: GEM, hunterId: TO, assignedBy: ADMIN },
        }),
      );
      expect(owners()).toEqual([FROM]); // the fake upsert wrote nothing
      expect(state.projects[0].ownerAdminId).toBe(FROM);
      expect(actions(audit)).toEqual(['project.hunter.invite.respond']);
      expect(audit.create.mock.calls[0][0].metadata).toEqual({
        projectId: GEM,
        status: 'accepted',
      });
    });
  });
});

describe('planHandover', () => {
  const at = (iso: string) => new Date(iso);

  it('is null when the sender is not an owner or hands to themself', () => {
    const project = {
      ownerAdminId: ADMIN,
      hunters: [{ id: 'a', hunterId: TO, createdAt: at('2026-01-01') }],
    };
    expect(planHandover(project, FROM, TO)).toBeNull();
    expect(planHandover(project, ADMIN, TO)).toBeNull();
    expect(planHandover(project, TO, TO)).toBeNull();
  });

  it('keeps a secondary co-owner’s slot secondary', () => {
    const plan = planHandover(
      {
        ownerAdminId: ADMIN,
        hunters: [
          { id: 'a', hunterId: ADMIN, createdAt: at('2026-01-01') },
          { id: 'b', hunterId: FROM, createdAt: at('2026-02-01') },
        ],
      },
      FROM,
      TO,
    );
    expect(plan).toEqual({
      deleteRowId: null,
      moveRow: { id: 'b', createdAt: at('2026-02-01') },
      createRow: false,
      moveOwnerAdmin: false,
    });
  });
});
