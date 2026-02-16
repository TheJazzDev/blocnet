import {
  Body,
  Controller,
  Headers,
  Post,
  UnauthorizedException,
} from '@nestjs/common';
import { VerifySessionDto } from './dto/verify-session.dto';
import { AuthService } from './auth.service';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('session/verify')
  async verifySession(
    @Body() body: VerifySessionDto,
    @Headers('authorization') authorization?: string,
  ) {
    const bodyToken = body.accessToken?.trim();
    const headerToken = authorization?.replace('Bearer ', '').trim();
    const token = bodyToken || headerToken;

    if (!token) {
      throw new UnauthorizedException('Missing access token');
    }

    const user = await this.authService.verifySession(token);
    return { user };
  }
}
