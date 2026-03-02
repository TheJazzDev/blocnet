import { Logger, ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import helmet from 'helmet';
import { randomUUID } from 'crypto';
import type { NextFunction, Request, Response } from 'express';
import { AppModule } from './app.module';

type CorsOriginCallback = (error: Error | null, allow?: boolean) => void;

function formatUnknownError(error: unknown): string {
  if (error instanceof Error) {
    return error.stack ?? error.message;
  }
  return String(error);
}

const bootstrapLogger = new Logger('Bootstrap');

process.on('unhandledRejection', (reason) => {
  bootstrapLogger.error(
    `Unhandled promise rejection: ${formatUnknownError(reason)}`,
  );
});

process.on('uncaughtException', (error) => {
  bootstrapLogger.error(`Uncaught exception: ${formatUnknownError(error)}`);
});

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  const logger = new Logger('RequestLogger');

  app.use(helmet());
  logger.log('Helmet middleware applied');

  const defaultAllowedOrigins = [
    'http://localhost:3081',
    'https://console.blocnet.app', // prod 1
    'https://stage-console.blocnet.app', // stage 1
    'https://blocnet-prod-console.vercel.app', // prod 2
    'https://blocnet-stage-console.vercel.app', // stage 2
  ];
  const envAllowedOrigins = (process.env.CORS_ORIGINS ?? '')
    .split(/[,\n;\s]+/)
    .map((origin) => origin.trim())
    .filter(Boolean);
  const allowAnyOrigin =
    process.env.CORS_ALLOW_ANY_ORIGIN === 'true' ||
    envAllowedOrigins.includes('*');
  const allowedOriginSet = new Set([
    ...defaultAllowedOrigins,
    ...envAllowedOrigins.filter((origin) => origin !== '*'),
  ]);
  const allowedOrigins = [...allowedOriginSet];

  app.enableCors({
    origin: (origin: string | undefined, callback: CorsOriginCallback) => {
      // Allow non-browser callers (e.g. server-to-server) without an Origin header.
      if (!origin) {
        callback(null, true);
        return;
      }

      if (allowAnyOrigin || allowedOriginSet.has(origin)) {
        callback(null, true);
        return;
      }

      callback(null, false);
    },
    methods: ['GET', 'POST', 'PATCH', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: [
      'Content-Type',
      'Authorization',
      'x-admin-view-as-role',
      'x-request-id',
      'apikey',
      'x-client-info',
    ],
    exposedHeaders: ['x-request-id'],
    credentials: true,
    optionsSuccessStatus: 204,
  });
  logger.log(
    `CORS origins configured: ${allowAnyOrigin ? '*' : allowedOrigins.join(', ')}`,
  );

  app.setGlobalPrefix('api');
  app.use((req: Request, res: Response, next: NextFunction) => {
    const startedAt = Date.now();
    const requestId = req.header('x-request-id') ?? randomUUID();
    let finished = false;

    res.setHeader('x-request-id', requestId);
    res.on('finish', () => {
      finished = true;
      const durationMs = Date.now() - startedAt;
      logger.log(
        `${req.method} ${req.originalUrl} ${res.statusCode} ${durationMs}ms requestId=${requestId}`,
      );
    });
    res.on('close', () => {
      if (finished) {
        return;
      }
      const durationMs = Date.now() - startedAt;
      logger.warn(
        `${req.method} ${req.originalUrl} closed before response after ${durationMs}ms requestId=${requestId}`,
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

void bootstrap().catch((error) => {
  bootstrapLogger.error(
    `Application bootstrap failed: ${formatUnknownError(error)}`,
  );
  process.exit(1);
});
