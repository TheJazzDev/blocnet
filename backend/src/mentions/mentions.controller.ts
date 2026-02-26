import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { AuthGuard } from '../common/guards/auth.guard';
import { MentionsService } from './mentions.service';
import { SearchUsersQuery } from './dto/search-users.query';

@ApiTags('mentions')
@Controller('mentions')
@UseGuards(AuthGuard)
export class MentionsController {
  constructor(private readonly mentionsService: MentionsService) {}

  @Get('search')
  @ApiOperation({ summary: 'Search users for mentions autocomplete' })
  async searchUsers(@Query() query: SearchUsersQuery) {
    return this.mentionsService.searchUsers(query.q, query.limit);
  }
}
