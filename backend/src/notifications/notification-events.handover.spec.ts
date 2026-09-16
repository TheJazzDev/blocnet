import { NotificationEventsService } from './notification-events.service';

const FROM = 'from-hunter';
const TO = 'to-hunter';

function createService() {
  const prisma = {
    project: {
      findUnique: jest.fn().mockResolvedValue({ name: 'Halo Points' }),
    },
    profile: {
      findUnique: jest.fn(({ where }: any) =>
        Promise.resolve({
          id: where.id,
          username: where.id,
          displayName: null,
          email: `${where.id}@x`,
        }),
      ),
    },
    projectHunterInvite: {
      findUnique: jest.fn().mockResolvedValue({
        id: 'inv-1',
        projectId: 'gem-1',
        invitedBy: FROM,
        status: 'accepted',
        project: { id: 'gem-1', name: 'Halo Points', ownerAdminId: 'admin-1' },
      }),
    },
    userRole: {
      findMany: jest
        .fn()
        .mockResolvedValue([
          { userId: 'admin-1' },
          { userId: TO },
          { userId: FROM },
        ]),
    },
  } as any;
  const config = { get: jest.fn().mockReturnValue(true) } as any;
  const notifications = { notifyMany: jest.fn().mockResolvedValue([]) };
  const service = new NotificationEventsService(
    prisma,
    config,
    notifications as any,
  );
  const sent = () => notifications.notifyMany.mock.calls[0]?.[0] ?? [];
  return { service, prisma, sent };
}

describe('NotificationEventsService — handovers', () => {
  it('tells the receiving hunter a gem is being handed over', async () => {
    const { service, sent } = createService();
    await service.emitForAudit({
      action: 'project.hunter.handover',
      actorId: FROM,
      resourceId: 'inv-1',
      metadata: { projectId: 'gem-1', hunterId: TO, round: 'r1' },
    });
    expect(sent()).toEqual([
      expect.objectContaining({
        userId: TO,
        type: 'project_invite_received',
        title: `${FROM} is handing over Halo Points`,
        deeplink: '/hunter-hub',
        dedupeKey: 'project.hunter.handover:inv-1:r1',
      }),
    ]);
  });

  it('tells only the handing hunter about the answer', async () => {
    const { service, sent } = createService();
    await service.emitForAudit({
      action: 'project.hunter.invite.respond',
      actorId: TO,
      resourceId: 'inv-1',
      metadata: {
        projectId: 'gem-1',
        status: 'rejected',
        kind: 'handover',
        round: 'r2',
      },
    });
    expect(sent()).toEqual([
      expect.objectContaining({
        userId: FROM,
        type: 'project_invite_responded',
        title: `${TO} declined to take over Halo Points`,
        body: 'The gem is still yours.',
      }),
    ]);
  });

  it('keeps co-own answers going to the inviter and the owning admin', async () => {
    const { service, sent } = createService();
    await service.emitForAudit({
      action: 'project.hunter.invite.respond',
      actorId: TO,
      resourceId: 'inv-1',
      metadata: { projectId: 'gem-1', status: 'accepted' },
    });
    expect(sent().map((e: any) => e.userId)).toEqual([FROM, 'admin-1']);
    expect(sent()[0].title).toBe(`${TO} accepted a project invite`);
  });

  it('puts an ownership move in front of admins, not the two hunters', async () => {
    const { service, prisma, sent } = createService();
    await service.emitForAudit({
      action: 'project.ownership.handover',
      actorId: TO,
      resourceId: 'gem-1',
      metadata: {
        projectId: 'gem-1',
        inviteId: 'inv-1',
        fromHunterId: FROM,
        toHunterId: TO,
        round: 'r3',
      },
    });
    expect(prisma.userRole.findMany.mock.calls[0][0].where.role).toEqual({
      in: ['owner', 'dev', 'admin'],
    });
    expect(sent()).toEqual([
      expect.objectContaining({
        userId: 'admin-1',
        type: 'project_assignment_changed',
        title: 'Halo Points changed hands',
        body: `${FROM} handed coverage over to ${TO}.`,
        dedupeKey: 'project.ownership.handover:inv-1:r3',
      }),
    ]);
  });
});
