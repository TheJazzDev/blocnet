import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UnauthorizedException,
  UseGuards,
} from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { AuthGuard } from '../common/guards/auth.guard';
import type { AuthUser } from '../common/interfaces/auth-user.interface';
import { CommentsService } from './comments.service';
import { CreateCommentDto } from './dto/create-comment.dto';
import { ListCommentsQuery } from './dto/list-comments.query';
import { UpdateCommentDto } from './dto/update-comment.dto';

@Controller()
export class CommentsController {
  constructor(private readonly commentsService: CommentsService) {}

  @Post('updates/:updateId/comments')
  @UseGuards(AuthGuard)
  async createComment(
    @CurrentUser() user: AuthUser | undefined,
    @Param('updateId') updateId: string,
    @Body() dto: CreateCommentDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.commentsService.createComment(user, updateId, dto);
  }

  @Get('updates/:updateId/comments')
  @UseGuards(AuthGuard)
  async listComments(
    @CurrentUser() user: AuthUser | undefined,
    @Param('updateId') updateId: string,
    @Query() query: ListCommentsQuery,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.commentsService.listComments(user, updateId, query);
  }

  @Patch('comments/:id')
  @UseGuards(AuthGuard)
  async updateComment(
    @CurrentUser() user: AuthUser | undefined,
    @Param('id') id: string,
    @Body() dto: UpdateCommentDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.commentsService.updateComment(user, id, dto);
  }

  @Delete('comments/:id')
  @UseGuards(AuthGuard)
  async deleteComment(
    @CurrentUser() user: AuthUser | undefined,
    @Param('id') id: string,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.commentsService.deleteComment(user, id);
  }
}
