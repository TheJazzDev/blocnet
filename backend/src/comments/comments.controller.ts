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

  @Post('posts/:postId/comments')
  @UseGuards(AuthGuard)
  async createComment(
    @CurrentUser() user: AuthUser | undefined,
    @Param('postId') postId: string,
    @Body() dto: CreateCommentDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.commentsService.createComment(user, postId, dto);
  }

  @Get('posts/:postId/comments')
  async listComments(
    @Param('postId') postId: string,
    @Query() query: ListCommentsQuery,
  ) {
    return this.commentsService.listComments(postId, query);
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
