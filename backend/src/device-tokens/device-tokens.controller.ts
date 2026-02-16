import {
  Body,
  Controller,
  Delete,
  Param,
  Post,
  UnauthorizedException,
  UseGuards,
} from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { AuthGuard } from '../common/guards/auth.guard';
import type { AuthUser } from '../common/interfaces/auth-user.interface';
import { RegisterDeviceTokenDto } from './dto/register-device-token.dto';
import { DeviceTokensService } from './device-tokens.service';

@Controller('device-tokens')
@UseGuards(AuthGuard)
export class DeviceTokensController {
  constructor(private readonly deviceTokensService: DeviceTokensService) {}

  @Post('register')
  async register(
    @CurrentUser() user: AuthUser | undefined,
    @Body() dto: RegisterDeviceTokenDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.deviceTokensService.register(user.id, dto);
  }

  @Delete(':id')
  async remove(
    @CurrentUser() user: AuthUser | undefined,
    @Param('id') id: string,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.deviceTokensService.remove(user.id, id);
  }
}
