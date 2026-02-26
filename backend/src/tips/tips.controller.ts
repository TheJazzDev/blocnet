import {
  Body,
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
import { CreateTipDto } from './dto/create-tip.dto';
import { ListTipHistoryQuery } from './dto/list-tip-history.query';
import { TipsService } from './tips.service';

@Controller('tips')
@UseGuards(AuthGuard)
export class TipsController {
  constructor(private readonly tipsService: TipsService) {}

  @Get('me')
  async getMyOverview(@CurrentUser() user: AuthUser | undefined) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }
    return this.tipsService.getMyOverview(user.id);
  }

  @Get('history')
  async listMyHistory(
    @CurrentUser() user: AuthUser | undefined,
    @Query() query: ListTipHistoryQuery,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }
    return this.tipsService.listMyHistory(user.id, query);
  }

  @Post('send')
  async sendTip(
    @CurrentUser() user: AuthUser | undefined,
    @Body() dto: CreateTipDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }
    return this.tipsService.sendTip(user.id, dto);
  }
}
