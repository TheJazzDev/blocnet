import {
  Body,
  Controller,
  Get,
  Patch,
  UnauthorizedException,
  UseGuards,
} from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { AuthGuard } from '../common/guards/auth.guard';
import type { AuthUser } from '../common/interfaces/auth-user.interface';
import { UpdateMeDto } from './dto/update-me.dto';
import { UsersService } from './users.service';

@Controller('me')
@UseGuards(AuthGuard)
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get()
  async getMe(@CurrentUser() user?: AuthUser) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.usersService.getMe(user.id);
  }

  @Patch()
  async updateMe(@CurrentUser() user: AuthUser | undefined, @Body() dto: UpdateMeDto) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.usersService.updateMe(user.id, dto);
  }
}
