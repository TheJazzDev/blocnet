import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
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
import { CreateProjectProposalDto } from './dto/create-project-proposal.dto';
import { ListProjectProposalsQuery } from './dto/list-project-proposals.query';
import { ReviewProjectProposalDto } from './dto/review-project-proposal.dto';
import { ProjectProposalsService } from './project-proposals.service';

@Controller('project-proposals')
@UseGuards(AuthGuard, RolesGuard)
export class ProjectProposalsController {
  constructor(
    private readonly projectProposalsService: ProjectProposalsService,
  ) {}

  @Post()
  @Roles(AppRole.OWNER, AppRole.ADMIN, AppRole.HUNTER)
  async create(
    @CurrentUser() user: AuthUser | undefined,
    @Body() dto: CreateProjectProposalDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.projectProposalsService.create(user, dto);
  }

  @Get('mine')
  async listMine(
    @CurrentUser() user: AuthUser | undefined,
    @Query() query: ListProjectProposalsQuery,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.projectProposalsService.listMine(user.id, query);
  }

  @Get()
  @Roles(AppRole.OWNER, AppRole.ADMIN, AppRole.MODERATOR)
  async listAll(@Query() query: ListProjectProposalsQuery) {
    return this.projectProposalsService.listAll(query);
  }

  @Patch(':id/review')
  @Roles(AppRole.OWNER, AppRole.ADMIN, AppRole.MODERATOR)
  async review(
    @CurrentUser() user: AuthUser | undefined,
    @Param('id') id: string,
    @Body() dto: ReviewProjectProposalDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.projectProposalsService.review(user, id, dto);
  }
}
