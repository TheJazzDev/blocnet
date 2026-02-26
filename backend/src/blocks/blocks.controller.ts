import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  UnauthorizedException,
  UseGuards,
} from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { AuthGuard } from '../common/guards/auth.guard';
import type { AuthUser } from '../common/interfaces/auth-user.interface';
import { BlocksService } from './blocks.service';
import { BlockUserDto } from './dto/block-user.dto';

@ApiTags('blocks')
@Controller('blocks')
@UseGuards(AuthGuard)
export class BlocksController {
  constructor(private readonly blocksService: BlocksService) {}

  @Post()
  @ApiOperation({ summary: 'Block a user' })
  async blockUser(
    @CurrentUser() user: AuthUser | undefined,
    @Body() dto: BlockUserDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.blocksService.blockUser(user.id, dto);
  }

  @Delete(':userId')
  @ApiOperation({ summary: 'Unblock a user' })
  async unblockUser(
    @CurrentUser() user: AuthUser | undefined,
    @Param('userId') userId: string,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.blocksService.unblockUser(user.id, userId);
  }

  @Get()
  @ApiOperation({ summary: 'Get list of blocked users' })
  async getBlockedUsers(@CurrentUser() user: AuthUser | undefined) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.blocksService.getBlockedUsers(user.id);
  }

  @Get('check/:userId')
  @ApiOperation({ summary: 'Check if a user is blocked' })
  async isBlocked(
    @CurrentUser() user: AuthUser | undefined,
    @Param('userId') userId: string,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    const blocked = await this.blocksService.isBlocked(user.id, userId);
    return { blocked };
  }
}
