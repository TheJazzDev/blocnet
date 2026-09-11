import { type INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { AuthGuard } from '../common/guards/auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { QuestsAdminController } from './quests-admin.controller';
import { QuestsService } from './quests.service';

// AuthGuard imports AuthService, which pulls in the ESM-only `jose` package.
jest.mock('jose', () => ({
  createRemoteJWKSet: jest.fn(),
  jwtVerify: jest.fn(),
}));

const QUEST_ID = '3f2b7c1e-9a4d-4c8e-b1f0-2d6a8e5c7b91';
const SUBMISSION_ID = 'a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d';

/**
 * Route-shape checks: static `submissions` paths must never be swallowed by
 * the `:questId` / `:submissionId` params, and non-UUID ids are rejected
 * before they reach the service.
 */
describe('QuestsAdminController (route shape)', () => {
  const questsService = {
    updateQuest: jest.fn(),
    getPendingSubmissions: jest.fn(),
    getSubmissionsByStatus: jest.fn(),
    verifyQuestSubmission: jest.fn(),
    revokeQuestSubmission: jest.fn(),
  };

  let app: INestApplication;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      controllers: [QuestsAdminController],
      providers: [{ provide: QuestsService, useValue: questsService }],
    })
      .overrideGuard(AuthGuard)
      .useValue({ canActivate: () => true })
      .overrideGuard(RolesGuard)
      .useValue({ canActivate: () => true })
      .compile();

    app = moduleRef.createNestApplication();
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        transform: true,
        forbidNonWhitelisted: true,
      }),
    );
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('GET /admin/quests/submissions reaches the submissions handler', async () => {
    questsService.getPendingSubmissions.mockResolvedValue([]);

    await request(app.getHttpServer())
      .get('/admin/quests/submissions')
      .expect(200);

    expect(questsService.getPendingSubmissions).toHaveBeenCalledWith(50, 0);
    expect(questsService.updateQuest).not.toHaveBeenCalled();
  });

  it('PATCH /admin/quests/submissions is rejected, never treated as questId', async () => {
    await request(app.getHttpServer())
      .patch('/admin/quests/submissions')
      .send({ title: 'Renamed' })
      .expect(400);

    expect(questsService.updateQuest).not.toHaveBeenCalled();
  });

  it('PATCH /admin/quests/:questId accepts a UUID', async () => {
    questsService.updateQuest.mockResolvedValue({ id: QUEST_ID });

    await request(app.getHttpServer())
      .patch(`/admin/quests/${QUEST_ID}`)
      .send({ title: 'Renamed' })
      .expect(200);

    expect(questsService.updateQuest).toHaveBeenCalledWith(
      QUEST_ID,
      { title: 'Renamed' },
      undefined,
    );
  });

  it('rejects non-UUID submission ids on approve/reject/revoke', async () => {
    for (const action of ['approve', 'reject', 'revoke']) {
      await request(app.getHttpServer())
        .post(`/admin/quests/submissions/not-a-uuid/${action}`)
        .send({})
        .expect(400);
    }

    expect(questsService.verifyQuestSubmission).not.toHaveBeenCalled();
    expect(questsService.revokeQuestSubmission).not.toHaveBeenCalled();
  });

  it('accepts a UUID submission id on approve', async () => {
    questsService.verifyQuestSubmission.mockResolvedValue({ ok: true });

    await request(app.getHttpServer())
      .post(`/admin/quests/submissions/${SUBMISSION_ID}/approve`)
      .send({})
      .expect(201);

    expect(questsService.verifyQuestSubmission).toHaveBeenCalledWith(
      { submissionId: SUBMISSION_ID, reviewNotes: undefined },
      undefined,
      true,
    );
  });
});
