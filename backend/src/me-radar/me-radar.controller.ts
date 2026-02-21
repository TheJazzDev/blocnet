import {
  Body,
  Controller,
  Get,
  Post,
  UnauthorizedException,
  UseGuards,
} from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { AuthGuard } from '../common/guards/auth.guard';
import type { AuthUser } from '../common/interfaces/auth-user.interface';
import { AckMeRadarDto } from './dto/ack-me-radar.dto';
import { MeRadarService } from './me-radar.service';

@Controller('me/radar')
@UseGuards(AuthGuard)
export class MeRadarController {
  constructor(private readonly meRadarService: MeRadarService) {}

  @Get()
  async getRadar(@CurrentUser() user: AuthUser | undefined) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.meRadarService.getRadar(user.id);
  }

  @Post('ack')
  async ack(
    @CurrentUser() user: AuthUser | undefined,
    @Body() dto: AckMeRadarDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }

    return this.meRadarService.ack(user.id, dto.seenAt);
  }
}
