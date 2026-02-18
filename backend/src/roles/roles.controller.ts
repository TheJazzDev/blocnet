import {
  Body,
  Controller,
  Param,
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
import { PromoteUserDto } from './dto/promote-user.dto';
import { RolesService } from './roles.service';

@Controller('roles')
@UseGuards(AuthGuard, RolesGuard)
export class RolesController {
  constructor(private readonly rolesService: RolesService) {}

  @Post('admins/:userId/promote')
  @Roles(AppRole.OWNER)
  async promoteAdmin(
    @CurrentUser() user: AuthUser | undefined,
    @Param('userId') userId: string,
    @Body() dto: PromoteUserDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.rolesService.promoteToAdmin(user.id, userId, dto.note);
  }

  @Post('hunters/:userId/promote')
  @Roles(AppRole.OWNER, AppRole.ADMIN)
  async promoteHunter(
    @CurrentUser() user: AuthUser | undefined,
    @Param('userId') userId: string,
    @Body() dto: PromoteUserDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.rolesService.promoteToHunter(user.id, userId, dto.note);
  }
}
