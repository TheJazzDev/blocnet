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
import { CreatePointsTransferDto } from './dto/create-points-transfer.dto';
import { CreateTipDto } from './dto/create-tip.dto';
import { ListTipHistoryQuery } from './dto/list-tip-history.query';
import { TipTransfersService } from './tip-transfers.service';
import { TipsService } from './tips.service';

@Controller('tips')
@UseGuards(AuthGuard)
export class TipsController {
  constructor(
    private readonly tipsService: TipsService,
    private readonly tipTransfersService: TipTransfersService,
  ) {}

  @Get('me')
  async getMyOverview(@CurrentUser() user: AuthUser | undefined) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }
    return this.tipsService.getMyOverview(user.id);
  }

  @Get('history')
  async listHistory(
    @CurrentUser() user: AuthUser | undefined,
    @Query() query: ListTipHistoryQuery,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }
    return this.tipsService.listTipHistory(user.id, query);
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

  /**
   * Member-to-member BNP transfer. Lives beside `/tips/send` because the BNP
   * ledger (accounts, locking, idempotency) is owned by this module; the
   * wallet module only reads it.
   */
  @Post('transfers')
  async sendTransfer(
    @CurrentUser() user: AuthUser | undefined,
    @Body() dto: CreatePointsTransferDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }
    return this.tipTransfersService.sendTransfer(user.id, dto);
  }
}
