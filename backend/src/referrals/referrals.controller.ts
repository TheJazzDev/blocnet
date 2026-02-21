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
import { BindReferralDto } from './dto/bind-referral.dto';
import { ListDownlineQuery } from './dto/list-downline.query';
import { ValidateReferralQuery } from './dto/validate-referral.query';
import { ReferralsService } from './referrals.service';

@Controller('referrals')
export class ReferralsController {
  constructor(private readonly referralsService: ReferralsService) {}

  @Get('validate')
  async validate(@Query() query: ValidateReferralQuery) {
    return this.referralsService.validateCode(query.code);
  }

  @Get('me')
  @UseGuards(AuthGuard)
  async me(@CurrentUser() user: AuthUser | undefined) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.referralsService.getMe(user.id);
  }

  @Post('bind')
  @UseGuards(AuthGuard)
  async bind(
    @CurrentUser() user: AuthUser | undefined,
    @Body() dto: BindReferralDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.referralsService.bind(user.id, dto.code);
  }

  @Get('downline')
  @UseGuards(AuthGuard)
  async downline(
    @CurrentUser() user: AuthUser | undefined,
    @Query() query: ListDownlineQuery,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.referralsService.listDownline(
      user.id,
      query.limit,
      query.offset,
    );
  }
}
