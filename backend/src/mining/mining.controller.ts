import {
  Controller,
  Get,
  Post,
  Query,
  UnauthorizedException,
  UseGuards,
} from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { AuthGuard } from '../common/guards/auth.guard';
import type { AuthUser } from '../common/interfaces/auth-user.interface';
import { ListMiningLeaderboardQuery } from './dto/list-mining-leaderboard.query';
import { MiningService } from './mining.service';
import { MiningLeaderboardService } from './mining-leaderboard.service';

@Controller('mining')
@UseGuards(AuthGuard)
export class MiningController {
  constructor(
    private readonly miningService: MiningService,
    private readonly miningLeaderboardService: MiningLeaderboardService,
  ) {}

  @Get('me')
  async getMe(@CurrentUser() user: AuthUser | undefined) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.miningService.getMe(user.id);
  }

  @Get('leaderboard')
  async leaderboard(
    @CurrentUser() user: AuthUser | undefined,
    @Query() query: ListMiningLeaderboardQuery,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.miningLeaderboardService.getLeaderboard({
      q: query.q,
      limit: query.limit,
      offset: query.offset,
      includePrivateFields: false,
    });
  }

  @Post('start')
  async start(@CurrentUser() user: AuthUser | undefined) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.miningService.start(user.id);
  }

  @Post('claim')
  async claim(@CurrentUser() user: AuthUser | undefined) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.miningService.claim(user.id);
  }
}
