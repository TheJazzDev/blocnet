import {
  Body,
  Controller,
  Post,
  UnauthorizedException,
  UseGuards,
} from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { AppRole } from '../common/enums/role.enum';
import { AuthGuard } from '../common/guards/auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import type { AuthUser } from '../common/interfaces/auth-user.interface';
import { AdminBindReferralDto } from './dto/admin-bind-referral.dto';
import { ReferralsService } from './referrals.service';

@Controller('admin/referrals')
@UseGuards(AuthGuard, RolesGuard)
@Roles(AppRole.OWNER, AppRole.ADMIN)
export class ReferralsAdminController {
  constructor(private readonly referralsService: ReferralsService) {}

  @Post('bind')
  async bindForUser(
    @CurrentUser() user: AuthUser | undefined,
    @Body() dto: AdminBindReferralDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.referralsService.bindByAdmin(user.id, dto.userIdOrEmail, dto.code);
  }
}
