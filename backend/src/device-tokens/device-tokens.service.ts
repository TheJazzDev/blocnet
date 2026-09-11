import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { RegisterDeviceTokenDto } from './dto/register-device-token.dto';

@Injectable()
export class DeviceTokensService {
  constructor(private readonly prisma: PrismaService) {}

  async register(userId: string, dto: RegisterDeviceTokenDto) {
    return this.prisma.deviceToken.upsert({
      where: { token: dto.token },
      update: {
        userId,
        platform: dto.platform,
        lastSeenAt: new Date(),
      },
      create: {
        userId,
        token: dto.token,
        platform: dto.platform,
      },
    });
  }

  async remove(userId: string, id: string) {
    const existing = await this.prisma.deviceToken.findFirst({
      where: {
        id,
        userId,
      },
      select: { id: true },
    });

    if (!existing) {
      return { deleted: false };
    }

    await this.prisma.deviceToken.delete({ where: { id: existing.id } });
    return { deleted: true };
  }

  /**
   * Delete by push-token value, scoped to the caller.
   *
   * `token` is globally unique, so the `userId` filter is what prevents one
   * user from unregistering another user's device. A token owned by someone
   * else is indistinguishable from an unknown token in the response.
   */
  async removeByToken(userId: string, token: string) {
    const existing = await this.prisma.deviceToken.findFirst({
      where: {
        token,
        userId,
      },
      select: { id: true },
    });

    if (!existing) {
      return { deleted: false };
    }

    await this.prisma.deviceToken.delete({ where: { id: existing.id } });
    return { deleted: true };
  }
}
