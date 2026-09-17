import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { HealthController } from './../src/health/health.controller';
import { HealthService } from './../src/health/health.service';

describe('Health (e2e)', () => {
  let app: INestApplication;

  beforeEach(async () => {
    const healthServiceMock: Pick<
      HealthService,
      'getHealth' | 'getLiveness' | 'getReadiness'
    > = {
      getHealth: () => ({
        status: 'ok',
        service: 'blocnet-backend',
      }),
      getLiveness: () => ({
        status: 'ok',
        service: 'blocnet-backend',
      }),
      getReadiness: () =>
        Promise.resolve({
          status: 'ok',
          service: 'blocnet-backend',
          checks: {
            database: { healthy: true },
            supabaseAuthConfigured: true,
          },
        }),
    };

    const moduleFixture: TestingModule = await Test.createTestingModule({
      controllers: [HealthController],
      providers: [
        {
          provide: HealthService,
          useValue: healthServiceMock,
        },
      ],
    }).compile();

    app = moduleFixture.createNestApplication();
    app.setGlobalPrefix('api');
    // Bind to the loopback address supertest dials; see F-71 in the unit specs.
    await app.listen(0, '127.0.0.1');
  });

  afterEach(async () => {
    await app.close();
  });

  it('/api/health (GET)', async () => {
    const server = app.getHttpServer() as Parameters<typeof request>[0];
    const response = await request(server).get('/api/health').expect(200);

    expect(response.body).toMatchObject({ status: 'ok' });
    expect(response.body).toMatchObject({ service: 'blocnet-backend' });
  });

  it('/api/health/live (GET)', async () => {
    const server = app.getHttpServer() as Parameters<typeof request>[0];
    const response = await request(server).get('/api/health/live').expect(200);

    expect(response.body).toMatchObject({ status: 'ok' });
  });

  it('/api/health/ready (GET)', async () => {
    const server = app.getHttpServer() as Parameters<typeof request>[0];
    const response = await request(server).get('/api/health/ready').expect(200);

    expect(response.body).toMatchObject({ status: 'ok' });
    expect(
      Object.prototype.hasOwnProperty.call(response.body as object, 'checks'),
    ).toBe(true);
  });
});
