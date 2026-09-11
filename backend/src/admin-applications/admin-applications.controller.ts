import {
  Body,
  Controller,
  Get,
  Patch,
  Post,
  Param,
  ParseUUIDPipe,
  Query,
  UnauthorizedException,
  UseGuards,
} from '@nestjs/common';
import { ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { AppRole } from '../common/enums/role.enum';
import { AuthGuard } from '../common/guards/auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import type { AuthUser } from '../common/interfaces/auth-user.interface';
import { AdminApplicationsService } from './admin-applications.service';
import { CreateAdminApplicationDto } from './dto/create-admin-application.dto';
import { ListMyApplicationsQueryDto } from './dto/list-my-applications-query.dto';
import { MyAdminApplicationResponseDto } from './dto/my-admin-application-response.dto';
import { ReviewAdminApplicationDto } from './dto/review-admin-application.dto';

@ApiTags('admin-applications')
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

  // Static path: declared before any `:id` route so `mine` is never read as an id.
  @Get('mine')
  @ApiOperation({
    summary: 'List my role applications',
    description:
      "Returns the signed-in user's own applications (any role), newest first. " +
      'Lets a client show approved/rejected state instead of assuming "pending".',
  })
  @ApiResponse({
    status: 200,
    description: "The caller's applications, newest first",
    type: [MyAdminApplicationResponseDto],
  })
  @ApiResponse({ status: 400, description: 'Invalid targetRole filter' })
  @ApiResponse({ status: 401, description: 'Missing or invalid bearer token' })
  async listMine(
    @CurrentUser() user: AuthUser | undefined,
    @Query() query: ListMyApplicationsQueryDto,
  ): Promise<MyAdminApplicationResponseDto[]> {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.adminApplicationsService.listMine(user.id, query);
  }

  @Get()
  @Roles(AppRole.OWNER, AppRole.ADMIN)
  async list() {
    return this.adminApplicationsService.list();
  }

  @Patch(':id/review')
  @Roles(AppRole.OWNER)
  async review(
    @CurrentUser() user: AuthUser | undefined,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: ReviewAdminApplicationDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.adminApplicationsService.review(user.id, id, dto);
  }
}
