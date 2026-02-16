import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  UnauthorizedException,
  Query,
  UseGuards,
} from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { AppRole } from '../common/enums/role.enum';
import { AuthGuard } from '../common/guards/auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import type { AuthUser } from '../common/interfaces/auth-user.interface';
import { CreateProjectDto } from './dto/create-project.dto';
import { UpdateProjectDto } from './dto/update-project.dto';
import { ProjectsService } from './projects.service';
import { ListProjectsQuery } from './dto/list-projects.query';

@Controller('projects')
export class ProjectsController {
  constructor(private readonly projectsService: ProjectsService) {}

  @Post()
  @UseGuards(AuthGuard, RolesGuard)
  @Roles(AppRole.OWNER, AppRole.ADMIN)
  async create(
    @CurrentUser() user: AuthUser | undefined,
    @Body() dto: CreateProjectDto,
  ) {
    if (!user) throw new UnauthorizedException('User context missing');
    return this.projectsService.createProject(user, dto);
  }

  @Get()
  async list(@Query() query: ListProjectsQuery) {
    return this.projectsService.listProjects(query);
  }

  @Get(':id')
  async getById(@Param('id') id: string) {
    return this.projectsService.getProject(id);
  }

  @Patch(':id')
  @UseGuards(AuthGuard, RolesGuard)
  @Roles(AppRole.OWNER, AppRole.ADMIN)
  async update(
    @CurrentUser() user: AuthUser | undefined,
    @Param('id') id: string,
    @Body() dto: UpdateProjectDto,
  ) {
    if (!user) throw new UnauthorizedException('User context missing');
    return this.projectsService.updateProject(user, id, dto);
  }
}
