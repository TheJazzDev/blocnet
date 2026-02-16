import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { UpdateMeDto } from './dto/update-me.dto';

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  async getMe(userId: string) {
    return this.prisma.profile.findUnique({
      where: { id: userId },
      include: {
        roles: {
          select: {
            role: true,
          },
        },
      },
    });
  }

  async updateMe(userId: string, dto: UpdateMeDto) {
    return this.prisma.profile.update({
      where: { id: userId },
      data: {
        displayName: dto.displayName,
        avatarUrl: dto.avatarUrl,
      },
    });
  }
}
