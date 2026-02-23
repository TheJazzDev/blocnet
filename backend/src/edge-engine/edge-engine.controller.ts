import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  Query,
  UnauthorizedException,
  UseGuards,
} from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { AuthGuard } from '../common/guards/auth.guard';
import type { AuthUser } from '../common/interfaces/auth-user.interface';
import { EdgeFeedbackDto } from './dto/edge-feedback.dto';
import { GetEdgeBriefQuery } from './dto/get-edge-brief.query';
import { ListEdgeFeedQuery } from './dto/list-edge-feed.query';
import { EdgeEngineService } from './edge-engine.service';

@Controller('me/edge')
@UseGuards(AuthGuard)
export class EdgeEngineController {
  constructor(private readonly edgeEngineService: EdgeEngineService) {}

  @Get('feed')
  async getFeed(
    @CurrentUser() user: AuthUser | undefined,
    @Query() query: ListEdgeFeedQuery,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.edgeEngineService.getFeed(user.id, query);
  }

  @Get('brief')
  async getBrief(
    @CurrentUser() user: AuthUser | undefined,
    @Query() query: GetEdgeBriefQuery,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.edgeEngineService.getBrief(user.id, query);
  }

  @Get('explain/:decisionId')
  async explain(
    @CurrentUser() user: AuthUser | undefined,
    @Param('decisionId') decisionId: string,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.edgeEngineService.explain(user.id, decisionId);
  }

  @Post('feedback')
  async feedback(
    @CurrentUser() user: AuthUser | undefined,
    @Body() dto: EdgeFeedbackDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.edgeEngineService.feedback(user.id, dto);
  }
}
