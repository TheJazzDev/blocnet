import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  Param,
  ParseUUIDPipe,
  Post,
  Query,
  UnauthorizedException,
  UseGuards,
} from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { AuthGuard } from '../common/guards/auth.guard';
import type { AuthUser } from '../common/interfaces/auth-user.interface';
import { RegisterDeviceTokenDto } from './dto/register-device-token.dto';
import { UnregisterDeviceTokenDto } from './dto/unregister-device-token.dto';
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

  /**
   * Unregister by token value.
   *
   * Clients hold the push token itself (FCM hands it to them) but not the
   * DeviceToken row id, so sign-out has no way to reach `DELETE
   * /device-tokens/:id`. Accepts the value as `?token=` or in the body so a
   * client can use whichever its HTTP helper supports. Always scoped to the
   * caller: a token belonging to another user is reported as not deleted.
   */
  @Delete()
  async unregister(
    @CurrentUser() user: AuthUser | undefined,
    @Query() query: UnregisterDeviceTokenDto,
    @Body() body: UnregisterDeviceTokenDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    const token = (query?.token ?? body?.token ?? '').trim();
    if (!token) {
      throw new BadRequestException(
        'token is required as a query parameter or in the request body',
      );
    }

    return this.deviceTokensService.removeByToken(user.id, token);
  }

  @Delete(':id')
  async remove(
    @CurrentUser() user: AuthUser | undefined,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.deviceTokensService.remove(user.id, id);
  }
}
