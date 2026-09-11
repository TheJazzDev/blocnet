import { Test } from '@nestjs/testing';
import { ApplicationTargetRole } from '@prisma/client';
import { AuditLogService } from '../audit-log/audit-log.service';
import { PrismaService } from '../prisma/prisma.service';
import { RolesService } from '../roles/roles.service';
import { AdminApplicationsService } from './admin-applications.service';

const CALLER_ID = '6d1f3c2a-8b4e-4f6a-9c1d-2e3f4a5b6c7d';

/** Query-shape checks for `listMine`: rows are always scoped to the caller. */
describe('AdminApplicationsService.listMine', () => {
  const prisma = {
    adminApplication: {
      findMany: jest.fn(),
    },
  };

  let service: AdminApplicationsService;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      providers: [
        AdminApplicationsService,
        { provide: PrismaService, useValue: prisma },
        { provide: RolesService, useValue: {} },
        { provide: AuditLogService, useValue: { create: jest.fn() } },
      ],
    }).compile();

    service = moduleRef.get(AdminApplicationsService);
  });

  beforeEach(() => {
    jest.clearAllMocks();
    prisma.adminApplication.findMany.mockResolvedValue([]);
  });

  it('scopes to the caller, orders newest first, and selects only the public fields', async () => {
    await service.listMine(CALLER_ID);

    expect(prisma.adminApplication.findMany).toHaveBeenCalledTimes(1);
    expect(prisma.adminApplication.findMany).toHaveBeenCalledWith({
      where: { userId: CALLER_ID },
      orderBy: { createdAt: 'desc' },
      select: {
        id: true,
        targetRole: true,
        status: true,
        reason: true,
        createdAt: true,
        reviewedAt: true,
      },
    });
  });

  it('adds the targetRole filter when provided', async () => {
    await service.listMine(CALLER_ID, {
      targetRole: ApplicationTargetRole.hunter,
    });

    expect(prisma.adminApplication.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { userId: CALLER_ID, targetRole: ApplicationTargetRole.hunter },
      }),
    );
  });

  it('never selects reviewedBy or userId', async () => {
    await service.listMine(CALLER_ID);

    const [args] = prisma.adminApplication.findMany.mock.calls[0];
    expect(args.select).not.toHaveProperty('reviewedBy');
    expect(args.select).not.toHaveProperty('userId');
  });
});
