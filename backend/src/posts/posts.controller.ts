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
import { CreatePostDto } from './dto/create-post.dto';
import { ListPostsQuery } from './dto/list-posts.query';
import { UpdatePostDto } from './dto/update-post.dto';
import { PostsService } from './posts.service';

@Controller()
export class PostsController {
  constructor(private readonly postsService: PostsService) {}

  @Post('projects/:projectId/posts')
  @UseGuards(AuthGuard, RolesGuard)
  @Roles(AppRole.OWNER, AppRole.ADMIN, AppRole.POSTER)
  async createPost(
    @CurrentUser() user: AuthUser | undefined,
    @Param('projectId') projectId: string,
    @Body() dto: CreatePostDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.postsService.createPost(user, projectId, dto);
  }

  @Get('posts')
  async listPosts(@Query() query: ListPostsQuery) {
    return this.postsService.listPosts(query);
  }

  @Get('posts/:id')
  async getPost(@Param('id') id: string) {
    return this.postsService.getPost(id);
  }

  @Patch('posts/:id')
  @UseGuards(AuthGuard, RolesGuard)
  @Roles(AppRole.OWNER, AppRole.ADMIN, AppRole.POSTER)
  async updatePost(
    @CurrentUser() user: AuthUser | undefined,
    @Param('id') id: string,
    @Body() dto: UpdatePostDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.postsService.updatePost(user, id, dto);
  }
}
