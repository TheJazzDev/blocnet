import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Query,
  UnauthorizedException,
  UseGuards,
} from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { AuthGuard } from '../common/guards/auth.guard';
import type { AuthUser } from '../common/interfaces/auth-user.interface';
import { CommunityPostsService } from './community-posts.service';
import { CreateCommunityPostCommentDto } from './dto/create-community-post-comment.dto';
import { CreateCommunityPostDto } from './dto/create-community-post.dto';
import { ListCommunityCommentsQuery } from './dto/list-community-comments.query';
import { ListCommunityPostsQuery } from './dto/list-community-posts.query';
import { ReactCommunityPostDto } from './dto/react-community-post.dto';

@Controller()
@UseGuards(AuthGuard)
export class CommunityPostsController {
  constructor(private readonly communityPostsService: CommunityPostsService) {}

  @Get('community-posts')
  async listPosts(
    @CurrentUser() user: AuthUser | undefined,
    @Query() query: ListCommunityPostsQuery,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.communityPostsService.listPosts(user, query);
  }

  @Get('community-posts/:id')
  async getPost(
    @CurrentUser() user: AuthUser | undefined,
    @Param('id') id: string,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.communityPostsService.getPost(user, id);
  }

  @Post('community-posts')
  async createPost(
    @CurrentUser() user: AuthUser | undefined,
    @Body() dto: CreateCommunityPostDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.communityPostsService.createPost(user, dto);
  }

  @Get('community-posts/:postId/comments')
  async listComments(
    @CurrentUser() user: AuthUser | undefined,
    @Param('postId') postId: string,
    @Query() query: ListCommunityCommentsQuery,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.communityPostsService.listComments(user, postId, query);
  }

  @Post('community-posts/:postId/comments')
  async createComment(
    @CurrentUser() user: AuthUser | undefined,
    @Param('postId') postId: string,
    @Body() dto: CreateCommunityPostCommentDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.communityPostsService.createComment(user, postId, dto);
  }

  @Post('community-posts/:postId/reactions')
  async reactToPost(
    @CurrentUser() user: AuthUser | undefined,
    @Param('postId') postId: string,
    @Body() dto: ReactCommunityPostDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.communityPostsService.reactToPost(user, postId, dto);
  }

  @Delete('community-posts/:postId/reactions')
  async removeReaction(
    @CurrentUser() user: AuthUser | undefined,
    @Param('postId') postId: string,
    @Query() query: ReactCommunityPostDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.communityPostsService.removeReaction(user, postId, query);
  }

  @Post('community-posts/:postId/bookmark')
  async bookmarkPost(
    @CurrentUser() user: AuthUser | undefined,
    @Param('postId') postId: string,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.communityPostsService.bookmarkPost(user, postId);
  }

  @Delete('community-posts/:postId/bookmark')
  async unbookmarkPost(
    @CurrentUser() user: AuthUser | undefined,
    @Param('postId') postId: string,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.communityPostsService.unbookmarkPost(user, postId);
  }

  @Post('community-post-comments/:commentId/reactions')
  async likeComment(
    @CurrentUser() user: AuthUser | undefined,
    @Param('commentId') commentId: string,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.communityPostsService.likeComment(user, commentId);
  }

  @Delete('community-post-comments/:commentId/reactions')
  async unlikeComment(
    @CurrentUser() user: AuthUser | undefined,
    @Param('commentId') commentId: string,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.communityPostsService.unlikeComment(user, commentId);
  }
}
