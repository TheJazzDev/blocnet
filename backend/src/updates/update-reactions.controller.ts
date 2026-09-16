import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Param,
  ParseUUIDPipe,
  Post,
  Put,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiOperation } from '@nestjs/swagger';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { AuthGuard } from '../common/guards/auth.guard';
import type { AuthUser } from '../common/interfaces/auth-user.interface';
import { ImportUpdateReactionsDto } from './dto/import-update-reactions.dto';
import { UpdateReactionsService } from './update-reactions.service';
import { UpdatesService } from './updates.service';

/** Likes and saves on updates, and the member's saved-updates list. */
@Controller()
@UseGuards(AuthGuard)
export class UpdateReactionsController {
  constructor(
    private readonly reactions: UpdateReactionsService,
    private readonly updatesService: UpdatesService,
  ) {}

  @Put('updates/:id/like')
  @ApiOperation({ summary: 'Like an update (idempotent)' })
  like(@CurrentUser() user: AuthUser, @Param('id', ParseUUIDPipe) id: string) {
    return this.reactions.like(user, id);
  }

  @Delete('updates/:id/like')
  @ApiOperation({ summary: 'Remove a like from an update (idempotent)' })
  unlike(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.reactions.unlike(user, id);
  }

  @Put('updates/:id/bookmark')
  @ApiOperation({ summary: 'Save an update (idempotent)' })
  bookmark(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.reactions.bookmark(user, id);
  }

  @Delete('updates/:id/bookmark')
  @ApiOperation({ summary: 'Unsave an update (idempotent)' })
  unbookmark(
    @CurrentUser() user: AuthUser,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.reactions.unbookmark(user, id);
  }

  @Get('me/bookmarks/updates')
  @ApiOperation({ summary: 'My saved updates, newest saved first' })
  listBookmarkedUpdates(
    @CurrentUser() user: AuthUser,
    @Query('limit') limit?: string,
    @Query('offset') offset?: string,
  ) {
    return this.updatesService.listBookmarkedUpdates(user, {
      limit: limit ? Number(limit) : undefined,
      offset: offset ? Number(offset) : undefined,
    });
  }

  @Post('me/update-reactions/import')
  @HttpCode(200)
  @ApiOperation({
    summary: 'One-time import of likes and saves held on the device',
  })
  importReactions(
    @CurrentUser() user: AuthUser,
    @Body() dto: ImportUpdateReactionsDto,
  ) {
    return this.reactions.importReactions(user, dto);
  }
}
