import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { KycStatus, Prisma } from '@prisma/client';
import { AuditLogService } from '../audit-log/audit-log.service';
import { FinancialAuditActions } from '../common/constants/financial-audit-actions';
import { normalizePagination } from '../common/utils/pagination.util';
import { PrismaService } from '../prisma/prisma.service';
import { ListWalletKycQuery } from './dto/list-wallet-kyc.query';
import { ReviewKycDto } from './dto/review-kyc.dto';

@Injectable()
export class WalletAdminKycService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auditLogService: AuditLogService,
  ) {}

  async listKyc(query: ListWalletKycQuery) {
    const { limit, offset } = normalizePagination(query.offset, query.limit);
    const q = query.q?.trim();
    const uuidRegex =
      /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    const isUuid = q ? uuidRegex.test(q) : false;

    const where = {
      ...(query.status ? { status: query.status } : {}),
      ...(q
        ? {
            OR: [
              {
                user: {
                  email: { contains: q, mode: 'insensitive' as const },
                },
              },
              {
                user: {
                  displayName: { contains: q, mode: 'insensitive' as const },
                },
              },
              ...(isUuid ? [{ userId: { equals: q } }] : []),
            ],
          }
        : {}),
    };

    const [rows, total] = await Promise.all([
      this.prisma.kycProfile.findMany({
        where,
        orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
        skip: offset,
        take: limit,
        include: {
          user: {
            select: {
              id: true,
              email: true,
              displayName: true,
            },
          },
          reviewer: {
            select: {
              id: true,
              email: true,
              displayName: true,
            },
          },
        },
      }),
      this.prisma.kycProfile.count({ where }),
    ]);

    return {
      data: rows.map((row) => ({
        id: row.id,
        userId: row.userId,
        user: row.user,
        status: row.status,
        tier: row.tier,
        country: row.country,
        fullName: row.fullName,
        documentType: row.documentType,
        documentNumberLast4: row.documentNumberLast4,
        documentUrl: row.documentUrl,
        submittedAt: row.submittedAt,
        reviewedAt: row.reviewedAt,
        reviewNote: row.reviewNote,
        reviewer: row.reviewer,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      })),
      total,
      limit,
      offset,
    };
  }

  async reviewKyc(actorId: string, userId: string, dto: ReviewKycDto) {
    if (
      dto.status !== KycStatus.approved &&
      dto.status !== KycStatus.rejected
    ) {
      throw new BadRequestException(
        'KYC review status must be approved or rejected',
      );
    }

    const existing = await this.prisma.kycProfile.findUnique({
      where: { userId },
    });

    if (!existing) {
      throw new NotFoundException('KYC profile not found');
    }

    const nextTier = dto.tier?.trim() || existing.tier;
    if (dto.status === KycStatus.approved) {
      const tierExists = await this.prisma.riskLimit.findUnique({
        where: { tier: nextTier },
        select: { id: true },
      });
      if (!tierExists) {
        throw new BadRequestException(`Unknown risk tier: ${nextTier}`);
      }
    }

    const updated = await this.prisma.kycProfile.update({
      where: { userId },
      data: {
        status: dto.status,
        tier: nextTier,
        reviewedBy: actorId,
        reviewedAt: new Date(),
        reviewNote: dto.note.trim(),
      },
    });

    await this.auditLogService.create({
      actorId,
      action: FinancialAuditActions.KycReviewed,
      resourceType: 'kyc_profile',
      resourceId: updated.id,
      metadata: {
        userId,
        status: updated.status,
        tier: updated.tier,
        note: dto.note,
      },
    });

    return updated;
  }
}
