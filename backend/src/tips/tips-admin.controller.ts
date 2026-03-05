import {
  Body,
  Controller,
  Get,
  Param,
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
import { ListAdminTipTransactionsQuery } from './dto/list-admin-tip-transactions.query';
import { SetActiveTipCurrencyDto } from './dto/set-active-tip-currency.dto';
import { UpdateTipCurrencyDto } from './dto/update-tip-currency.dto';
import { TipsService } from './tips.service';

@Controller('admin/tips')
@UseGuards(AuthGuard, RolesGuard)
@Roles(AppRole.OWNER, AppRole.ADMIN)
export class TipsAdminController {
  constructor(private readonly tipsService: TipsService) {}

  @Get('settings')
  async getSettings() {
    return this.tipsService.getAdminSettings();
  }

  @Patch('settings/currencies/:currencyCode')
  @Roles(AppRole.OWNER, AppRole.ADMIN)
  async updateCurrencySettings(
    @CurrentUser() user: AuthUser | undefined,
    @Param('currencyCode') currencyCode: string,
    @Body() dto: UpdateTipCurrencyDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }
    return this.tipsService.updateCurrencySettings(user.id, currencyCode, dto);
  }

  @Patch('settings/active-currency')
  @Roles(AppRole.OWNER, AppRole.ADMIN)
  async setActiveCurrency(
    @CurrentUser() user: AuthUser | undefined,
    @Body() dto: SetActiveTipCurrencyDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }
    return this.tipsService.setActiveCurrency(user.id, dto.currencyCode);
  }

  @Get('transactions')
  async listTransactions(@Query() query: ListAdminTipTransactionsQuery) {
    return this.tipsService.listAdminTransactions(query);
  }
}
