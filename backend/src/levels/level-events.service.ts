import { Injectable, Logger } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { UserLevel } from '@prisma/client';

export interface LevelUpEvent {
  userId: string;
  previousLevel: UserLevel | null;
  newLevel: UserLevel;
  timestamp: Date;
}

@Injectable()
export class LevelEventsService {
  private readonly logger = new Logger(LevelEventsService.name);

  constructor(private eventEmitter: EventEmitter2) {}

  async emitLevelUp(event: LevelUpEvent): Promise<void> {
    this.logger.log(
      `User ${event.userId} leveled up: ${event.previousLevel?.level || 0} → ${event.newLevel.level}`,
    );
    this.eventEmitter.emit('level.up', event);
  }

  async emitLevelRecalculated(userId: string): Promise<void> {
    this.eventEmitter.emit('level.recalculated', { userId });
  }
}
