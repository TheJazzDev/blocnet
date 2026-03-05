import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { RuntimeFeatureFlagsService } from './runtime-feature-flags.service';

type UpsertClosedAlphaEmailInput = {
  email: string;
  note?: string | null;
  isActive?: boolean;
  source: 'landing' | 'admin';
  createdById?: string;
};

@Injectable()
export class ClosedAlphaAccessService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly runtimeFeatureFlagsService: RuntimeFeatureFlagsService,
  ) {}

  async getPublicStatus(): Promise<{ enabled: boolean }> {
    const config = await this.runtimeFeatureFlagsService.getConfig();
    return { enabled: config.closedAlphaEnabled };
  }

  async addLandingEmail(email: string) {
    return this.upsertEmail({
      email,
      source: 'landing',
      isActive: true,
    });
  }

  async listEmails(params: { q?: string; limit?: number; offset?: number }) {
    const limit = Math.min(Math.max(params.limit ?? 50, 1), 200);
    const offset = Math.max(params.offset ?? 0, 0);
    const query = params.q?.trim();
    const normalizedQuery = query?.toLowerCase();

    const where = query
      ? {
          OR: [
            {
              email: {
                contains: query,
                mode: 'insensitive' as const,
              },
            },
            {
              emailNormalized: {
                contains: normalizedQuery,
              },
            },
          ],
        }
      : undefined;

    const [data, total] = await this.prisma.$transaction([
      this.prisma.closedAlphaAccessEmail.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        take: limit,
        skip: offset,
      }),
      this.prisma.closedAlphaAccessEmail.count({ where }),
    ]);

    return { data, total, limit, offset };
  }

  async addAdminEmail(input: {
    email: string;
    note?: string | null;
    isActive?: boolean;
    createdById?: string;
  }) {
    return this.upsertEmail({
      email: input.email,
      note: input.note,
      isActive: input.isActive ?? true,
      source: 'admin',
      createdById: input.createdById,
    });
  }

  async setActive(id: string, isActive: boolean) {
    return this.prisma.closedAlphaAccessEmail.update({
      where: { id },
      data: { isActive },
    });
  }

  async remove(id: string) {
    return this.prisma.closedAlphaAccessEmail.delete({
      where: { id },
    });
  }

  async isEmailAllowed(email: string): Promise<boolean> {
    const normalized = this.normalizeEmail(email);
    if (!normalized) return false;

    const row = await this.prisma.closedAlphaAccessEmail.findUnique({
      where: { emailNormalized: normalized },
      select: { id: true, isActive: true },
    });

    return row?.isActive === true;
  }

  private async upsertEmail(input: UpsertClosedAlphaEmailInput) {
    const normalized = this.normalizeEmail(input.email);
    const safeNote = input.note?.trim() || null;
    const isActive = input.isActive ?? true;

    return this.prisma.closedAlphaAccessEmail.upsert({
      where: { emailNormalized: normalized },
      update: {
        email: normalized,
        isActive,
        source: input.source,
        note: safeNote,
        ...(input.createdById ? { createdById: input.createdById } : {}),
      },
      create: {
        email: normalized,
        emailNormalized: normalized,
        isActive,
        source: input.source,
        note: safeNote,
        createdById: input.createdById ?? null,
      },
    });
  }

  private normalizeEmail(email: string): string {
    return email.trim().toLowerCase();
  }
}
