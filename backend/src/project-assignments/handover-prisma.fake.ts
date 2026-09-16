/* eslint-disable @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-unsafe-return, @typescript-eslint/no-unsafe-argument -- a loose Prisma stand-in; the specs check its results. */
/**
 * An in-memory stand-in for the slice of Prisma the handover touches, so the
 * specs can assert on the resulting ownership rather than on call shapes.
 * Test-only.
 */

export interface FakeProfile {
  id: string;
  username: string | null;
  displayName: string | null;
  isDeactivated: boolean;
  roles: string[];
}

export interface FakeInvite {
  id: string;
  projectId: string;
  hunterId: string;
  invitedBy: string;
  note: string | null;
  kind: 'co_own' | 'handover';
  status: 'pending' | 'accepted' | 'rejected' | 'cancelled';
  reviewedBy: string | null;
  reviewedAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
}

export interface FakeState {
  profiles: FakeProfile[];
  projects: { id: string; name: string; ownerAdminId: string }[];
  hunters: {
    id: string;
    projectId: string;
    hunterId: string;
    assignedBy: string;
    createdAt: Date;
  }[];
  invites: FakeInvite[];
}

let seq = 0;
const nextId = (prefix: string) => `${prefix}-${++seq}`;

function matches(
  row: Record<string, any>,
  where: Record<string, any>,
): boolean {
  return Object.entries(where).every(([key, value]) => {
    if (key === 'OR') {
      return (value as Record<string, any>[]).some((w) => matches(row, w));
    }
    return row[key] === value;
  });
}

export function createFakePrisma(state: FakeState) {
  const huntersOf = (projectId: string) =>
    state.hunters
      .filter((row) => row.projectId === projectId)
      .sort((a, b) => a.createdAt.getTime() - b.createdAt.getTime());

  const profileView = (p: FakeProfile) => ({
    id: p.id,
    username: p.username,
    displayName: p.displayName,
    isDeactivated: p.isDeactivated,
    roles: p.roles.map((role) => ({ role })),
  });

  const prisma: any = {
    $transaction: jest.fn((fn: (tx: any) => Promise<unknown>) => fn(prisma)),
    $queryRaw: jest.fn((_strings: TemplateStringsArray, projectId: string) =>
      Promise.resolve(
        state.projects
          .filter((p) => p.id === projectId)
          .map((p) => ({ id: p.id })),
      ),
    ),
    profile: {
      findUnique: jest.fn(({ where }: any) => {
        const p = state.profiles.find((row) => row.id === where.id);
        return Promise.resolve(p ? profileView(p) : null);
      }),
      findFirst: jest.fn(({ where }: any) => {
        const wanted = String(where.username.equals).toLowerCase();
        const p = state.profiles.find(
          (row) => row.username?.toLowerCase() === wanted,
        );
        return Promise.resolve(p ? profileView(p) : null);
      }),
    },
    userRole: {
      findFirst: jest.fn(({ where }: any) => {
        const p = state.profiles.find((row) => row.id === where.userId);
        return Promise.resolve(
          p?.roles.includes(where.role) ? { id: `role-${p.id}` } : null,
        );
      }),
    },
    project: {
      findUniqueOrThrow: jest.fn(({ where }: any) => {
        const project = state.projects.find((p) => p.id === where.id);
        if (!project) return Promise.reject(new Error('not found'));
        return Promise.resolve({
          ownerAdminId: project.ownerAdminId,
          hunters: huntersOf(project.id).map((row) => ({
            id: row.id,
            hunterId: row.hunterId,
            createdAt: row.createdAt,
          })),
        });
      }),
      update: jest.fn(({ where, data }: any) => {
        const project = state.projects.find((p) => p.id === where.id)!;
        Object.assign(project, data);
        return Promise.resolve(project);
      }),
      /** Shaped like `ReliabilityLoader.loadGems` reads it. */
      findMany: jest.fn(() =>
        Promise.resolve(
          state.projects.map((p) => ({
            id: p.id,
            name: p.name,
            createdAt: new Date('2026-01-01T00:00:00Z'),
            ownerAdminId: p.ownerAdminId,
            primaryTag: { name: 'CORE' },
            hunters: huntersOf(p.id).map((row) => ({ hunterId: row.hunterId })),
          })),
        ),
      ),
    },
    projectHunter: {
      create: jest.fn(({ data }: any) => {
        const row = { id: nextId('ph'), createdAt: new Date(), ...data };
        state.hunters.push(row);
        return Promise.resolve(row);
      }),
      update: jest.fn(({ where, data }: any) => {
        const row = state.hunters.find((r) => r.id === where.id)!;
        Object.assign(row, data);
        return Promise.resolve(row);
      }),
      delete: jest.fn(({ where }: any) => {
        const index = state.hunters.findIndex((r) => r.id === where.id);
        const [row] = state.hunters.splice(index, 1);
        return Promise.resolve(row);
      }),
    },
    projectHunterInvite: {
      findMany: jest.fn(({ where }: any) =>
        Promise.resolve(state.invites.filter((row) => matches(row, where))),
      ),
      findFirst: jest.fn(({ where }: any) =>
        Promise.resolve(
          state.invites.find((row) => matches(row, where)) ?? null,
        ),
      ),
      findUnique: jest.fn(({ where }: any) =>
        Promise.resolve(
          state.invites.find((row) => row.id === where.id) ?? null,
        ),
      ),
      findUniqueOrThrow: jest.fn(({ where }: any) =>
        Promise.resolve(state.invites.find((row) => row.id === where.id)!),
      ),
      upsert: jest.fn(({ where, update, create }: any) => {
        const key = where.projectId_hunterId;
        const existing = state.invites.find(
          (row) =>
            row.projectId === key.projectId && row.hunterId === key.hunterId,
        );
        const now = new Date(Date.now() + ++seq);
        if (existing) {
          Object.assign(existing, update, { updatedAt: now });
          return Promise.resolve(existing);
        }
        const row: FakeInvite = {
          id: nextId('inv'),
          note: null,
          kind: 'co_own',
          status: 'pending',
          reviewedBy: null,
          reviewedAt: null,
          createdAt: now,
          updatedAt: now,
          ...create,
        };
        state.invites.push(row);
        return Promise.resolve(row);
      }),
      update: jest.fn(({ where, data }: any) => {
        const row = state.invites.find((r) => r.id === where.id)!;
        Object.assign(row, data, { updatedAt: new Date() });
        return Promise.resolve(row);
      }),
      updateMany: jest.fn(({ where, data }: any) => {
        const rows = state.invites.filter((row) => matches(row, where));
        for (const row of rows) {
          Object.assign(row, data, { updatedAt: new Date() });
        }
        return Promise.resolve({ count: rows.length });
      }),
    },
  };
  return prisma;
}
