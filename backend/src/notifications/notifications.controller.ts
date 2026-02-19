import {
  Body,
  Controller,
  Get,
  Patch,
  Post,
  Param,
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
import { ListNotificationsQuery } from './dto/list-notifications.query';
import { BroadcastNotificationDto } from './dto/broadcast-notification.dto';
import { NotificationsService } from './notifications.service';
import { FcmService } from './fcm.service';

@Controller('notifications')
@UseGuards(AuthGuard)
export class NotificationsController {
  constructor(
    private readonly notificationsService: NotificationsService,
    private readonly fcmService: FcmService,
  ) {}

  @Get()
  async list(
    @CurrentUser() user: AuthUser | undefined,
    @Query() query: ListNotificationsQuery,
  ) {
    if (!user) throw new UnauthorizedException('User context missing');
    return this.notificationsService.listForUser(user.id, query);
  }

  @Patch(':id/read')
  async markRead(
    @CurrentUser() user: AuthUser | undefined,
    @Param('id') id: string,
  ) {
    if (!user) throw new UnauthorizedException('User context missing');
    return this.notificationsService.markAsRead(user.id, id);
  }

  @Post('broadcast')
  @UseGuards(RolesGuard)
  @Roles(AppRole.ADMIN, AppRole.OWNER)
  async broadcast(
    @CurrentUser() user: AuthUser | undefined,
    @Body() dto: BroadcastNotificationDto,
  ) {
    if (!user) throw new UnauthorizedException('User context missing');

    // Persist in-app notifications and push FCM in parallel
    const [dbResult, fcmResult] = await Promise.all([
      this.notificationsService.createBroadcast({
        title: dto.title,
        body: dto.body,
        target: dto.target,
        userIds: dto.userIds,
      }),
      this.fcmService.sendBroadcast({
        title: dto.title,
        body: dto.body,
        target: dto.target,
        userIds: dto.userIds,
      }),
    ]);

    return {
      insertedCount: dbResult.insertedCount,
      sentCount: fcmResult.sentCount,
      failureCount: (fcmResult as any).failureCount ?? 0,
      recipientCount: (fcmResult as any).recipientCount ?? dbResult.insertedCount,
      skipped: fcmResult.skipped,
    };
  }
}
