import {
  Body,
  Controller,
  ForbiddenException,
  Get,
  Post,
  Query,
} from '@nestjs/common';
import { ClosedAlphaAccessService } from './closed-alpha-access.service';
import { JoinClosedAlphaDto } from './dto/join-closed-alpha.dto';

@Controller('public/closed-alpha')
export class ClosedAlphaPublicController {
  constructor(private readonly closedAlphaAccessService: ClosedAlphaAccessService) {}

  @Get('status')
  async getStatus() {
    return this.closedAlphaAccessService.getPublicStatus();
  }

  @Get('check')
  async checkEmail(@Query('email') email?: string) {
    const status = await this.closedAlphaAccessService.getPublicStatus();
    if (!status.enabled) {
      return { enabled: false, allowed: true };
    }

    const normalized = email?.trim().toLowerCase();
    if (!normalized) {
      return { enabled: true, allowed: false };
    }

    const allowed = await this.closedAlphaAccessService.isEmailAllowed(
      normalized,
    );
    return { enabled: true, allowed };
  }

  @Post('join')
  async join(@Body() dto: JoinClosedAlphaDto) {
    const status = await this.closedAlphaAccessService.getPublicStatus();
    if (!status.enabled) {
      throw new ForbiddenException('Closed alpha signup is currently disabled');
    }

    const row = await this.closedAlphaAccessService.addLandingEmail(dto.email);
    return {
      ok: true,
      email: row.email,
      isActive: row.isActive,
      createdAt: row.createdAt,
    };
  }
}
