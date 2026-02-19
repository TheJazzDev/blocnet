import {
  Body,
  Controller,
  Get,
  Patch,
  Post,
  Param,
  UnauthorizedException,
  UseGuards,
} from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { AppRole } from '../common/enums/role.enum';
import { AuthGuard } from '../common/guards/auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import type { AuthUser } from '../common/interfaces/auth-user.interface';
import { AdminApplicationsService } from './admin-applications.service';
import { CreateAdminApplicationDto } from './dto/create-admin-application.dto';
import { ReviewAdminApplicationDto } from './dto/review-admin-application.dto';

@Controller('admin-applications')
@UseGuards(AuthGuard, RolesGuard)
export class AdminApplicationsController {
  constructor(
    private readonly adminApplicationsService: AdminApplicationsService,
  ) {}

  @Post()
  async create(
    @CurrentUser() user: AuthUser | undefined,
    @Body() dto: CreateAdminApplicationDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.adminApplicationsService.create(user.id, dto);
  }

  @Get()
  @Roles(AppRole.OWNER, AppRole.ADMIN, AppRole.MODERATOR)
  async list() {
    return this.adminApplicationsService.list();
  }

  @Patch(':id/review')
  @Roles(AppRole.OWNER)
  async review(
    @CurrentUser() user: AuthUser | undefined,
    @Param('id') id: string,
    @Body() dto: ReviewAdminApplicationDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.adminApplicationsService.review(user.id, id, dto);
  }
}
