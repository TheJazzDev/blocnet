import {
  Body,
  Controller,
  Delete,
  Get,
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

  @Get('matrix')
  @Roles(AppRole.OWNER, AppRole.DEV, AppRole.ADMIN, AppRole.MODERATOR)
  getMatrix() {
    return this.rolesService.getRolesMatrix();
  }

  @Post('admins/:userId/promote')
  @Roles(AppRole.OWNER, AppRole.DEV)
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

  @Post('owners/:userId/promote')
  @Roles(AppRole.OWNER)
  async promoteOwner(
    @CurrentUser() user: AuthUser | undefined,
    @Param('userId') userId: string,
    @Body() dto: PromoteUserDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.rolesService.promoteToOwner(user.id, userId, dto.note);
  }

  @Delete('owners/:userId')
  @Roles(AppRole.OWNER)
  async demoteOwner(
    @CurrentUser() user: AuthUser | undefined,
    @Param('userId') userId: string,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.rolesService.demoteOwner(user.id, userId);
  }

  @Delete('admins/:userId')
  @Roles(AppRole.OWNER, AppRole.DEV)
  async demoteAdmin(
    @CurrentUser() user: AuthUser | undefined,
    @Param('userId') userId: string,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.rolesService.demoteAdmin(user.id, userId);
  }

  @Post('moderators/:userId/promote')
  @Roles(AppRole.OWNER, AppRole.ADMIN)
  async promoteModerator(
    @CurrentUser() user: AuthUser | undefined,
    @Param('userId') userId: string,
    @Body() dto: PromoteUserDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.rolesService.promoteToModerator(user.id, userId, dto.note);
  }

  @Post('core-teams/:userId/promote')
  @Roles(AppRole.OWNER)
  async promoteCoreTeam(
    @CurrentUser() user: AuthUser | undefined,
    @Param('userId') userId: string,
    @Body() dto: PromoteUserDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.rolesService.promoteToCoreTeam(user.id, userId, dto.note);
  }

  @Delete('core-teams/:userId')
  @Roles(AppRole.OWNER)
  async demoteCoreTeam(
    @CurrentUser() user: AuthUser | undefined,
    @Param('userId') userId: string,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.rolesService.demoteCoreTeam(user.id, userId);
  }

  @Delete('moderators/:userId')
  @Roles(AppRole.OWNER, AppRole.ADMIN)
  async demoteModerator(
    @CurrentUser() user: AuthUser | undefined,
    @Param('userId') userId: string,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.rolesService.demoteModerator(user.id, userId);
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

  @Delete('hunters/:userId')
  @Roles(AppRole.OWNER, AppRole.ADMIN)
  async demoteHunter(
    @CurrentUser() user: AuthUser | undefined,
    @Param('userId') userId: string,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.rolesService.demoteHunter(user.id, userId);
  }

  @Post('devs/:userId/promote')
  @Roles(AppRole.OWNER)
  async promoteDev(
    @CurrentUser() user: AuthUser | undefined,
    @Param('userId') userId: string,
    @Body() dto: PromoteUserDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.rolesService.promoteToDev(user.id, userId, dto.note);
  }

  @Delete('devs/:userId')
  @Roles(AppRole.OWNER)
  async demoteDev(
    @CurrentUser() user: AuthUser | undefined,
    @Param('userId') userId: string,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.rolesService.demoteDev(user.id, userId);
  }
}
