import {
  Body,
  Controller,
  Get,
  Headers,
  Param,
  Post,
  Query,
  ServiceUnavailableException,
  UnauthorizedException,
  UseGuards,
} from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { AppRole } from '../common/enums/role.enum';
import { AuthGuard } from '../common/guards/auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import type { AuthUser } from '../common/interfaces/auth-user.interface';
import { PrismaService } from '../prisma/prisma.service';
import { SocialWebhooksService } from './social-webhooks.service';

@Controller()
export class SocialWebhooksController {
  constructor(
    private readonly socialWebhooksService: SocialWebhooksService,
    private readonly prisma: PrismaService,
  ) {}

  @Post('webhooks/social/:provider')
  async receiveWebhook(
    @Param('provider') provider: string,
    @Body() payload: Record<string, unknown>,
    @Headers('x-social-webhook-secret') secretHeader?: string,
    @Headers('x-webhook-secret') genericSecretHeader?: string,
    @Headers('authorization') authorization?: string,
    @Headers('x-request-id') requestId?: string,
    @Headers('x-forwarded-for') sourceIp?: string,
  ) {
    if (!this.socialWebhooksService.isConfigured()) {
      throw new ServiceUnavailableException(
        'Social webhook secret is not configured',
      );
    }

    const bearerToken = authorization?.replace(/^Bearer\s+/i, '').trim();
    const secret = secretHeader ?? genericSecretHeader ?? bearerToken;
    if (!this.socialWebhooksService.verifySecret(secret)) {
      throw new UnauthorizedException('Invalid social webhook secret');
    }

    return this.socialWebhooksService.processWebhook({
      provider,
      payload: payload ?? {},
      requestId,
      sourceIp,
    });
  }

  @Get('admin/social/overview')
  @UseGuards(AuthGuard, RolesGuard)
  @Roles(AppRole.OWNER, AppRole.ADMIN)
  async getOverview(
    @CurrentUser() user: AuthUser | undefined,
    @Query('limit') limit?: string,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    const safeLimit = Math.min(Math.max(Number(limit ?? 100), 1), 300);
    const rows = await this.prisma.auditLog.findMany({
      where: {
        action: {
          startsWith: 'ops.social.',
        },
      },
      orderBy: { createdAt: 'desc' },
      take: safeLimit,
      include: {
        actor: {
          select: { id: true, email: true, displayName: true },
        },
      },
    });

    const recent = rows.map((row) => {
      const metadata =
        row.metadata && typeof row.metadata === 'object' && !Array.isArray(row.metadata)
          ? (row.metadata as Record<string, unknown>)
          : {};

      return {
        id: row.id,
        action: row.action,
        provider:
          typeof metadata.provider === 'string' ? metadata.provider : 'unknown',
        accountHandle:
          typeof metadata.accountHandle === 'string'
            ? metadata.accountHandle
            : null,
        accountId:
          typeof metadata.accountId === 'string' ? metadata.accountId : null,
        metrics:
          metadata.metrics &&
          typeof metadata.metrics === 'object' &&
          !Array.isArray(metadata.metrics)
            ? (metadata.metrics as Record<string, unknown>)
            : {},
        summary:
          typeof metadata.summary === 'string'
            ? metadata.summary
            : `${row.resourceType} event`,
        createdAt: row.createdAt,
      };
    });

    const latestByProvider = new Map<string, (typeof recent)[number]>();
    for (const item of recent) {
      if (!latestByProvider.has(item.provider)) {
        latestByProvider.set(item.provider, item);
      }
    }

    return {
      total: recent.length,
      latestByProvider: [...latestByProvider.values()],
      recent,
    };
  }
}
