import {
  Body,
  Controller,
  Get,
  Patch,
  Query,
  UnauthorizedException,
  UseGuards,
} from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { AppRole } from '../common/enums/role.enum';
import { AuthGuard } from '../common/guards/auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import type { AuthUser } from '../common/interfaces/auth-user.interface';
import { ListMiningLeaderboardQuery } from './dto/list-mining-leaderboard.query';
import { UpdateMiningConfigDto } from './dto/update-mining-config.dto';
import { MiningService } from './mining.service';

@Controller('admin/mining')
@UseGuards(AuthGuard, RolesGuard)
@Roles(AppRole.OWNER, AppRole.ADMIN, AppRole.MODERATOR)
export class MiningAdminController {
  constructor(private readonly miningService: MiningService) {}

  @Get('config')
  async getConfig() {
    return this.miningService.getAdminConfig();
  }

  @Patch('config')
  @Roles(AppRole.OWNER, AppRole.ADMIN)
  async updateConfig(
    @CurrentUser() user: AuthUser | undefined,
    @Body() dto: UpdateMiningConfigDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.miningService.updateAdminConfig(user.id, dto);
  }

  @Get('metrics')
  async getMetrics() {
    return this.miningService.getAdminMetrics();
  }

  @Get('leaderboard')
  async getLeaderboard(@Query() query: ListMiningLeaderboardQuery) {
    return this.miningService.getLeaderboard({
      q: query.q,
      limit: query.limit,
      offset: query.offset,
      includePrivateFields: true,
    });
  }
}
