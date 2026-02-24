import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { AuthGuard } from '../common/guards/auth.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { RolesGuard } from '../common/guards/roles.guard';
import { AppRole } from '../common/enums/role.enum';
import { CreateQuestDto } from './dto/create-quest.dto';
import { UpdateQuestDto } from './dto/update-quest.dto';
import { QuestResponseDto } from './dto/quest-response.dto';
import { QuestsService } from './quests.service';

@ApiTags('admin/quests')
@Controller('admin/quests')
@UseGuards(AuthGuard, RolesGuard)
@Roles(AppRole.ADMIN, AppRole.OWNER)
export class QuestsAdminController {
  constructor(private readonly questsService: QuestsService) {}

  @Post()
  @ApiOperation({ summary: 'Admin: Create a new quest' })
  @ApiResponse({
    status: 201,
    description: 'Quest created successfully',
    type: QuestResponseDto,
  })
  async createQuest(
    @Body() dto: CreateQuestDto,
    @CurrentUser('id') adminId: string,
  ) {
    return this.questsService.createQuest(dto, adminId);
  }

  @Get()
  @ApiOperation({ summary: 'Admin: Get all quests including inactive' })
  @ApiResponse({
    status: 200,
    description: 'List of all quests',
    type: [QuestResponseDto],
  })
  async getAllQuestsAdmin(@Query('includeInactive') includeInactive?: string) {
    return this.questsService.getAllQuests(includeInactive === 'true');
  }

  @Patch(':questId')
  @ApiOperation({ summary: 'Admin: Update a quest' })
  @ApiResponse({
    status: 200,
    description: 'Quest updated successfully',
    type: QuestResponseDto,
  })
  async updateQuest(
    @Param('questId') questId: string,
    @Body() dto: UpdateQuestDto,
    @CurrentUser('id') adminId: string,
  ) {
    return this.questsService.updateQuest(questId, dto, adminId);
  }

  @Get('submissions')
  @ApiOperation({ summary: 'Admin: Get quest submissions' })
  @ApiResponse({
    status: 200,
    description: 'List of submissions',
  })
  async getSubmissions(
    @Query('status') status?: string,
    @Query('limit') limit?: string,
    @Query('offset') offset?: string,
  ) {
    if (status) {
      return this.questsService.getSubmissionsByStatus(
        status,
        limit ? parseInt(limit) : 50,
        offset ? parseInt(offset) : 0,
      );
    }
    return this.questsService.getPendingSubmissions(
      limit ? parseInt(limit) : 50,
      offset ? parseInt(offset) : 0,
    );
  }

  @Post('submissions/:submissionId/approve')
  @ApiOperation({ summary: 'Admin: Approve quest submission' })
  @ApiResponse({
    status: 200,
    description: 'Submission approved and rewards awarded',
  })
  async approveSubmission(
    @Param('submissionId') submissionId: string,
    @Body() dto: { reviewNotes?: string },
    @CurrentUser('id') adminId: string,
  ) {
    return this.questsService.verifyQuestSubmission(
      { submissionId, reviewNotes: dto.reviewNotes },
      adminId,
      true,
    );
  }

  @Post('submissions/:submissionId/reject')
  @ApiOperation({ summary: 'Admin: Reject quest submission' })
  @ApiResponse({
    status: 200,
    description: 'Submission rejected',
  })
  async rejectSubmission(
    @Param('submissionId') submissionId: string,
    @Body() dto: { reviewNotes?: string; rejectionReason?: string },
    @CurrentUser('id') adminId: string,
  ) {
    return this.questsService.verifyQuestSubmission(
      {
        submissionId,
        reviewNotes: dto.reviewNotes,
        rejectionReason: dto.rejectionReason,
      },
      adminId,
      false,
    );
  }
}
