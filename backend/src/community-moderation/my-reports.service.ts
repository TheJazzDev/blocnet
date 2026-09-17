import { Injectable } from '@nestjs/common';
import type { Prisma } from '@prisma/client';
import { normalizePagination } from '../common/utils/pagination.util';
import { PrismaService } from '../prisma/prisma.service';
import {
  COMMUNITY_REPORT_STATUS,
  type CommunityReportStatus,
} from './community-moderation.types';
import { ListCommunityReportsQuery } from './dto/list-community-reports.query';

/**
 * The reports a member filed, for their own "My reports" list.
 *
 * The moderation list (`GET /community/moderation/reports`) is staff-only and
 * returns everyone's reports with reporter and target emails, so it cannot
 * back a member-facing screen. This returns only the caller's rows, and only
 * the fields a reporter should see: no reviewer identity, no target account.
 */
@Injectable()
export class MyReportsService {
  constructor(private readonly prisma: PrismaService) {}

  async listMine(reporterId: string, query: ListCommunityReportsQuery) {
    const { offset, limit } = normalizePagination(query.offset, query.limit);

    const where: Prisma.CommunityModerationReportWhereInput = {
      reporterId,
      status: query.status,
      targetType: query.targetType,
    };

    const [rows, total, grouped] = await Promise.all([
      this.prisma.communityModerationReport.findMany({
        where,
        orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
        skip: offset,
        take: limit,
        select: {
          id: true,
          reporterId: true,
          targetType: true,
          targetId: true,
          reason: true,
          details: true,
          status: true,
          reviewedAt: true,
          resolutionNote: true,
          createdAt: true,
          updatedAt: true,
        },
      }),
      this.prisma.communityModerationReport.count({ where }),
      this.prisma.communityModerationReport.groupBy({
        by: ['status'],
        where: { reporterId },
        _count: { _all: true },
      }),
    ]);

    return {
      data: rows,
      total,
      limit,
      offset,
      counts: toStatusCounts(grouped),
    };
  }
}

function toStatusCounts(
  grouped: Array<{ status: string; _count: { _all: number } }>,
): Record<CommunityReportStatus, number> {
  const counts: Record<CommunityReportStatus, number> = {
    [COMMUNITY_REPORT_STATUS.open]: 0,
    [COMMUNITY_REPORT_STATUS.resolved]: 0,
    [COMMUNITY_REPORT_STATUS.dismissed]: 0,
  };
  for (const row of grouped) {
    if (row.status in counts) {
      counts[row.status as CommunityReportStatus] = row._count._all;
    }
  }
  return counts;
}
