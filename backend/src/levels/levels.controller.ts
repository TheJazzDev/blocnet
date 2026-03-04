import {
  BadRequestException,
  Controller,
  Get,
  NotFoundException,
  Patch,
  Param,
  Body,
  UseGuards,
  Query,
  Post,
  UploadedFile,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { LevelsService } from './levels.service';
import { AuthGuard } from '../common/guards/auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import type { AuthUser } from '../common/interfaces/auth-user.interface';
import { AppRole } from '../common/enums/role.enum';
import {
  LevelResponseDto,
  UserLevelProgressDto,
  LeaderboardEntryDto,
} from './dto/level-response.dto';
import { UpdateLevelDto } from './dto/update-level.dto';
import { LevelIconStorageService } from './level-icon-storage.service';

@Controller('levels')
export class LevelsController {
  constructor(
    private readonly levelsService: LevelsService,
    private readonly levelIconStorageService: LevelIconStorageService,
  ) {}

  /**
   * Get all levels
   * GET /api/levels
   */
  @Get()
  async getAllLevels(): Promise<LevelResponseDto[]> {
    const levels = await this.levelsService.getAllLevels();
    return levels.map((level) => LevelResponseDto.fromEntity(level));
  }

  /**
   * Get current user's level progress
   * GET /api/levels/me
   */
  @UseGuards(AuthGuard)
  @Get('me')
  async getMyLevelProgress(
    @CurrentUser() user: AuthUser,
  ): Promise<UserLevelProgressDto> {
    const result = await this.levelsService.getUserLevelWithProgress(user.id);

    return {
      currentLevel: LevelResponseDto.fromEntity(result.currentLevel),
      nextLevel: result.nextLevel
        ? LevelResponseDto.fromEntity(result.nextLevel)
        : null,
      achievedAt: result.progress.achievedAt,
      metrics: {
        totalBnpEarned: result.progress.totalBnpEarned.toString(),
        totalComments: result.progress.totalComments,
        totalDaysActive: result.progress.totalDaysActive,
        totalQuestsCompleted: result.progress.totalQuestsCompleted,
        totalUpdates: result.progress.totalUpdates,
        totalProjects: result.progress.totalProjects,
      },
      progressToNext: result.progressToNext
        ? {
            bnp: {
              current: result.progressToNext.bnp.current.toString(),
              required: result.progressToNext.bnp.required.toString(),
              percentage: result.progressToNext.bnp.percentage,
            },
            comments: result.progressToNext.comments,
            daysActive: result.progressToNext.daysActive,
            quests: result.progressToNext.quests,
            updates: result.progressToNext.updates,
            projects: result.progressToNext.projects,
          }
        : null,
    };
  }

  /**
   * Get specific user's level progress (public)
   * GET /api/levels/user/:userId
   */
  @Get('user/:userId')
  async getUserLevelProgress(
    @Param('userId') userId: string,
  ): Promise<UserLevelProgressDto> {
    const result = await this.levelsService.getUserLevelWithProgress(userId);

    return {
      currentLevel: LevelResponseDto.fromEntity(result.currentLevel),
      nextLevel: result.nextLevel
        ? LevelResponseDto.fromEntity(result.nextLevel)
        : null,
      achievedAt: result.progress.achievedAt,
      metrics: {
        totalBnpEarned: result.progress.totalBnpEarned.toString(),
        totalComments: result.progress.totalComments,
        totalDaysActive: result.progress.totalDaysActive,
        totalQuestsCompleted: result.progress.totalQuestsCompleted,
        totalUpdates: result.progress.totalUpdates,
        totalProjects: result.progress.totalProjects,
      },
      progressToNext: result.progressToNext
        ? {
            bnp: {
              current: result.progressToNext.bnp.current.toString(),
              required: result.progressToNext.bnp.required.toString(),
              percentage: result.progressToNext.bnp.percentage,
            },
            comments: result.progressToNext.comments,
            daysActive: result.progressToNext.daysActive,
            quests: result.progressToNext.quests,
            updates: result.progressToNext.updates,
            projects: result.progressToNext.projects,
          }
        : null,
    };
  }

  /**
   * Recalculate current user's level
   * POST /api/levels/me/recalculate
   */
  @UseGuards(AuthGuard)
  @Patch('me/recalculate')
  async recalculateMyLevel(@CurrentUser() user: AuthUser): Promise<{
    levelChanged: boolean;
    previousLevel: LevelResponseDto | null;
    currentLevel: LevelResponseDto;
  }> {
    const result = await this.levelsService.updateUserLevel(user.id);

    return {
      levelChanged: result.levelChanged,
      previousLevel: result.previousLevel
        ? LevelResponseDto.fromEntity(result.previousLevel)
        : null,
      currentLevel: LevelResponseDto.fromEntity(result.currentLevel),
    };
  }

  /**
   * Get leaderboard
   * GET /api/levels/leaderboard
   */
  @Get('leaderboard')
  async getLeaderboard(
    @Query('limit') limit?: string,
  ): Promise<LeaderboardEntryDto[]> {
    const parsedLimit = limit ? parseInt(limit, 10) : 100;
    const leaderboard = await this.levelsService.getLeaderboard(parsedLimit);

    return leaderboard.map((entry) => ({
      ...entry,
      level: LevelResponseDto.fromEntity(entry.level),
    }));
  }

  /**
   * Admin: Update level configuration
   * PATCH /api/levels/:id
   */
  @UseGuards(AuthGuard, RolesGuard)
  @Roles(AppRole.ADMIN, AppRole.OWNER)
  @Patch(':id')
  async updateLevelConfig(
    @Param('id') id: string,
    @Body() updateDto: UpdateLevelDto,
  ): Promise<LevelResponseDto> {
    const existingLevel = await this.levelsService.getLevelById(id);
    if (!existingLevel) {
      throw new NotFoundException('Level not found');
    }

    const data: any = { ...updateDto };

    // Convert requiredBnp string to BigInt if provided
    if (updateDto.requiredBnp) {
      data.requiredBnp = BigInt(updateDto.requiredBnp);
    }

    const updated = await this.levelsService.updateLevelConfig(id, data);
    if (
      typeof data.iconUrl === 'string' &&
      data.iconUrl.length > 0 &&
      data.iconUrl !== existingLevel.iconUrl
    ) {
      await this.levelIconStorageService.deletePreviousLevelIconIfManaged(
        existingLevel.iconUrl,
        data.iconUrl,
      );
    }

    return LevelResponseDto.fromEntity(updated);
  }

  /**
   * Admin: Upload level icon
   * POST /api/levels/:id/icon
   */
  @UseGuards(AuthGuard, RolesGuard)
  @Roles(AppRole.ADMIN, AppRole.OWNER)
  @Post(':id/icon')
  @UseInterceptors(
    FileInterceptor('file', {
      limits: {
        fileSize: 3 * 1024 * 1024,
      },
    }),
  )
  async uploadLevelIcon(
    @Param('id') id: string,
    @UploadedFile()
    file?: {
      buffer: Buffer;
      mimetype: string;
      size: number;
    },
  ): Promise<LevelResponseDto> {
    if (!file) {
      throw new BadRequestException('Icon file is required');
    }

    const existingLevel = await this.levelsService.getLevelById(id);
    if (!existingLevel) {
      throw new NotFoundException('Level not found');
    }

    const iconUrl = await this.levelIconStorageService.uploadLevelIcon(id, file);
    try {
      const updated = await this.levelsService.updateLevelConfig(id, { iconUrl });
      await this.levelIconStorageService.deletePreviousLevelIconIfManaged(
        existingLevel.iconUrl,
        iconUrl,
      );
      return LevelResponseDto.fromEntity(updated);
    } catch (error) {
      await this.levelIconStorageService.deleteManagedLevelIconIfManaged(iconUrl);
      throw error;
    }
  }

  /**
   * Admin: Get specific level
   * GET /api/levels/:id
   */
  @Get(':id')
  async getLevelById(@Param('id') id: string): Promise<LevelResponseDto> {
    const level = await this.levelsService.getLevelById(id);
    if (!level) {
      throw new NotFoundException('Level not found');
    }
    return LevelResponseDto.fromEntity(level);
  }
}
