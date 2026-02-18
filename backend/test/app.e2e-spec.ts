import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { HealthModule } from './../src/health/health.module';

describe('Health (e2e)', () => {
  let app: INestApplication;

  beforeEach(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [HealthModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    app.setGlobalPrefix('api');
    await app.init();
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
