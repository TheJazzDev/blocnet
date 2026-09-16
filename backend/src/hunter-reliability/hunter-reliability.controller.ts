import {
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Query,
  UnauthorizedException,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { AppRole } from '../common/enums/role.enum';
import { AuthGuard } from '../common/guards/auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import type { AuthUser } from '../common/interfaces/auth-user.interface';
import {
  HunterBoardResponseDto,
  HunterLeaderboardResponseDto,
  HunterReliabilityDto,
} from './dto/hunter-reliability-response.dto';
import { ListHunterLeaderboardQuery } from './dto/list-hunter-leaderboard.query';
import { HunterReliabilityService } from './hunter-reliability.service';

@ApiTags('hunters')
@ApiBearerAuth()
@Controller('hunters')
@UseGuards(AuthGuard)
export class HunterReliabilityController {
  constructor(private readonly reliability: HunterReliabilityService) {}

  @Get('leaderboard')
  @ApiOperation({
    summary:
      'Hunters who keep at least one live gem, ranked by reliability: standing, coverage, response, then updates in the last 30 days.',
  })
  @ApiOkResponse({ type: HunterLeaderboardResponseDto })
  async leaderboard(@Query() query: ListHunterLeaderboardQuery) {
    return this.reliability.getLeaderboard(query);
  }

  @Get(':profileId/reliability')
  @ApiOperation({
    summary:
      'A hunter’s reliability — coverage, cadence, response and standing — plus reach figures.',
  })
  @ApiOkResponse({ type: HunterReliabilityDto })
  async reliabilityFor(@Param('profileId', ParseUUIDPipe) profileId: string) {
    return this.reliability.getReliability(profileId);
  }
}

/**
 * The same roles that may post an update (`UpdatesController`): hunters, and
 * owners/admins (dev is implied by owner/admin in `RolesGuard`).
 */
const HUNTER_CAPABLE_ROLES = [AppRole.OWNER, AppRole.ADMIN, AppRole.HUNTER];

@ApiTags('hunters')
@ApiBearerAuth()
@Controller('me/hunter')
@UseGuards(AuthGuard, RolesGuard)
export class MyHunterBoardController {
  constructor(private readonly reliability: HunterReliabilityService) {}

  @Get('board')
  @Roles(...HUNTER_CAPABLE_ROLES)
  @ApiOperation({
    summary:
      'The caller’s own gems, worst first (quiet, due, current), with their reliability as the header.',
  })
  @ApiOkResponse({ type: HunterBoardResponseDto })
  async board(@CurrentUser() user: AuthUser | undefined) {
    if (!user) throw new UnauthorizedException('User context missing');
    return this.reliability.getBoard(user.id);
  }
}
