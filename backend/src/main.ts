import { Logger, ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import helmet from 'helmet';
import { randomUUID } from 'crypto';
import type { NextFunction, Request, Response } from 'express';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  const logger = new Logger('RequestLogger');

  app.use(helmet());
  logger.log('Helmet middleware applied');

  const allowedOrigins = [
    'http://localhost:3081', // admin panel (local)
    'http://localhost:3000', // landing page (local)
    ...(process.env.CORS_ORIGINS
      ? process.env.CORS_ORIGINS.split(',').map((o) => o.trim())
      : []),
  ];

  app.enableCors({
    origin: allowedOrigins,
    methods: ['GET', 'POST', 'PATCH', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
    credentials: true,
  });

  app.setGlobalPrefix('api');
  app.use((req: Request, res: Response, next: NextFunction) => {
    const startedAt = Date.now();
    const requestId = req.header('x-request-id') ?? randomUUID();

    res.setHeader('x-request-id', requestId);
    res.on('finish', () => {
      const durationMs = Date.now() - startedAt;
      logger.log(
        `${req.method} ${req.originalUrl} ${res.statusCode} ${durationMs}ms requestId=${requestId}`,
      );
    });

    next();
  });
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: true,
    }),
  );

  const swaggerConfig = new DocumentBuilder()
    .setTitle('Blocknet API')
    .setDescription('Backend API for Blocknet mobile and admin applications.')
    .setVersion('1.0.0')
    .addBearerAuth(
      {
        type: 'http',
        scheme: 'bearer',
        bearerFormat: 'JWT',
        description: 'Supabase access token',
      },
      'bearer',
    )
    .build();
  const swaggerDocument = SwaggerModule.createDocument(app, swaggerConfig);
  SwaggerModule.setup('api/docs', app, swaggerDocument, {
    swaggerOptions: {
      persistAuthorization: true,
    },
  });

  const port = Number(process.env.PORT ?? 3080);
  // Listen on all interfaces so physical devices on the same network can reach
  // the dev server (e.g. flutter build apk with API_BASE_URL=http://<lan-ip>:3080/api).
  await app.listen(port, '0.0.0.0');
}

void bootstrap();
