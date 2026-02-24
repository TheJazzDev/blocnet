import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { QuestStatus } from '@prisma/client';
import { AuthGuard } from '../common/guards/auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { SubmitQuestProofDto } from './dto/quest-action.dto';
import {
  QuestResponseDto,
  QuestSubmissionResponseDto,
  UserQuestsListResponseDto,
} from './dto/quest-response.dto';
import { QuestsService } from './quests.service';

@ApiTags('quests')
@Controller('quests')
@UseGuards(AuthGuard)
export class QuestsController {
  constructor(private readonly questsService: QuestsService) {}

  @Get()
  @ApiOperation({ summary: 'Get all active quests' })
  @ApiResponse({
    status: 200,
    description: 'List of all active quests',
    type: [QuestResponseDto],
  })
  async getAllQuests() {
    return this.questsService.getAllQuests();
  }

  @Get('me')
  @ApiOperation({ summary: 'Get my quests with progress' })
  @ApiResponse({
    status: 200,
    description: 'Current user quests',
    type: UserQuestsListResponseDto,
  })
  async getMyQuests(
    @CurrentUser('id') userId: string,
    @Query('status') status?: QuestStatus,
  ) {
    return this.questsService.getUserQuests(userId, status);
  }

  @Get('me/with-progress')
  @ApiOperation({ summary: 'Get all quests with my progress' })
  @ApiResponse({
    status: 200,
    description: 'All quests with user progress',
  })
  async getQuestsWithProgress(@CurrentUser('id') userId: string) {
    return this.questsService.getQuestsWithProgress(userId);
  }

  @Post(':questSlug/start')
  @ApiOperation({ summary: 'Start a quest' })
  @ApiResponse({
    status: 201,
    description: 'Quest started successfully',
  })
  async startQuest(
    @CurrentUser('id') userId: string,
    @Param('questSlug') questSlug: string,
  ) {
    return this.questsService.startQuest(userId, questSlug);
  }

  @Post(':questSlug/submit')
  @ApiOperation({ summary: 'Submit quest proof for verification' })
  @ApiResponse({
    status: 201,
    description: 'Proof submitted successfully',
    type: QuestSubmissionResponseDto,
  })
  async submitQuestProof(
    @CurrentUser('id') userId: string,
    @Param('questSlug') questSlug: string,
    @Body() dto: SubmitQuestProofDto,
  ) {
    return this.questsService.submitQuestProof(userId, questSlug, dto);
  }

  @Post(':questSlug/claim')
  @ApiOperation({ summary: 'Claim quest reward (auto-verified quests only)' })
  @ApiResponse({
    status: 200,
    description: 'Reward claimed successfully',
  })
  async claimQuestReward(
    @CurrentUser('id') userId: string,
    @Param('questSlug') questSlug: string,
  ) {
    return this.questsService.claimQuestReward(userId, questSlug);
  }
}
