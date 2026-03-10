# Blocnet Community Moderation - Complete Implementation Plan

## Executive Summary

This document outlines the complete implementation plan for Phase 3 (Enhanced Admin Console) and all identified gaps/recommendations (High, Medium, Low priority). It also evaluates the strategic option of creating a dedicated "Moderation Space" similar to the Hunter role space.

**Timeline**: 4-6 weeks for complete implementation
**Team Size**: 1-2 developers
**Risk Level**: Low (building on existing foundation)

---

## Strategic Decision: Dedicated Moderation Space

### Current Architecture Analysis

**Existing Spaces in Mobile App**:
1. **Home** - Project discovery feed
2. **Community** - Social posts and discussions
3. **Hunter** - Dedicated workspace for project curators with:
   - Project queue management
   - Submission review tools
   - Analytics dashboard
   - Quick actions optimized for curation workflow

**Current Moderation Access**:
- Moderators access tools via "Staff Tools" in Community tab
- Mixed with regular community content
- No dedicated analytics or workflow optimization
- Limited batch operations

### Recommendation: **CREATE DEDICATED MODERATION SPACE**

**Rationale**:
1. **Complexity Justification**: With Phase 3 + all gaps implemented, moderation will have:
   - User report queue (posts, comments, profiles, messages)
   - Appeal review queue
   - Moderation history/audit log
   - User management tools (suspend, restrict, ban)
   - Bulk actions dashboard
   - Analytics (resolution times, moderator performance, violation trends)
   - Auto-escalation rule configuration
   - **Total: 7+ major subsystems** - too complex for single Staff Tools screen

2. **Workflow Optimization**: Dedicated space allows:
   - Persistent filters and queue state
   - Quick keyboard shortcuts
   - Optimized layouts for scanning/reviewing
   - No context switching with community browsing

3. **Role Clarity**: Clear separation between:
   - **Community Tab** = User-facing social features
   - **Moderation Space** = Staff-only governance tools

4. **Scalability**: As platform grows, moderation tools will expand (ML suggestions, user reputation, advanced analytics) - needs dedicated space

### Proposed Architecture

```
Bottom Navigation:
┌─────────┬──────────┬──────────┬──────────┬──────────┐
│  Home   │Community │Moderation│  Hunter  │ Profile  │
│  (All)  │  (All)   │ (Staff)  │(Hunters) │  (All)   │
└─────────┴──────────┴──────────┴──────────┴──────────┘

Moderation Space Structure:
moderation/
├── pages/
│   ├── moderation_hub_screen.dart           # Main dashboard
│   ├── reports_queue_screen.dart            # Report review queue
│   ├── appeals_queue_screen.dart            # Appeal review queue
│   ├── user_management_screen.dart          # Suspend/restrict/ban tools
│   ├── moderation_history_screen.dart       # Audit log
│   ├── moderation_analytics_screen.dart     # Performance metrics
│   └── moderation_settings_screen.dart      # Auto-escalation rules
└── widgets/
    ├── moderation_nav_rail.dart             # Left sidebar navigation
    ├── queue_filter_bar.dart                # Advanced filters
    ├── bulk_action_toolbar.dart             # Multi-select actions
    └── moderation_stats_card.dart           # Quick stats
```

**Access Control**:
```dart
// In protected_routes.dart
if (authStore.isCommunityModerator ||
    authStore.isCommunityAdmin ||
    authStore.isAdmin) {
  // Show Moderation tab in bottom nav
}
```

---

## Implementation Phases

### Phase 0: Critical Foundation (Week 1, Days 1-2)
**Goal**: Fix blocking issues before building new features

#### Task 0.1: Backend Status Field Verification ⚠️ CRITICAL
**Priority**: HIGH
**Effort**: 2 hours
**Owner**: Backend Dev

**Steps**:
1. Verify `CommunityPost` and `CommunityPostComment` DTOs include `status` field:
   ```typescript
   // backend/src/community/dto/community-post-response.dto.ts
   export class CommunityPostResponseDto {
     @Expose()
     status: CommunityContentModerationStatus; // ← Must exist
   }

   // backend/src/community/dto/community-post-comment-response.dto.ts
   export class CommunityPostCommentResponseDto {
     @Expose()
     status: CommunityContentModerationStatus; // ← Must exist
   }
   ```

2. Test API responses:
   ```bash
   # Get post with status
   curl -H "Authorization: Bearer $TOKEN" \
     http://localhost:3080/api/community/posts/{postId}

   # Should return: { "id": "...", "status": "hidden", ... }
   ```

3. If missing, add to DTOs with `@Expose()` decorator

**Acceptance Criteria**:
- [ ] All post/comment API responses include `status` field
- [ ] Mobile app displays "HIDDEN"/"ARCHIVED" badges correctly
- [ ] Moderators can see hidden content in feeds

---

### Phase 1: Dedicated Moderation Space Foundation (Week 1, Days 3-5)
**Goal**: Create dedicated navigation and hub screen

#### Task 1.1: Add Moderation Navigation Tab
**Priority**: HIGH
**Effort**: 4 hours
**Files**:
- `lib/routes/bottom_nav.dart` (or equivalent)
- `lib/routes/protected_routes.dart`

**Implementation**:
```dart
// Add to bottom navigation items
BottomNavigationBarItem(
  icon: Icon(Icons.shield_outlined),
  activeIcon: Icon(Icons.shield),
  label: 'Moderation',
),

// Add route protection
if (authStore.isCommunityModerator ||
    authStore.isCommunityAdmin ||
    authStore.isAdmin) {
  return ModerationHubScreen();
} else {
  return AccessDeniedScreen(message: 'Moderator access required');
}
```

#### Task 1.2: Create Moderation Hub Dashboard
**Priority**: HIGH
**Effort**: 8 hours
**New File**: `lib/features/moderation/presentation/pages/moderation_hub_screen.dart`

**UI Components**:
```dart
class ModerationHubScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Moderation Hub'),
        actions: [
          // Quick settings access
          IconButton(icon: Icon(Icons.settings), onTap: ...),
        ],
      ),
      body: Column(
        children: [
          // Stats overview cards
          _StatsOverviewSection(),

          // Quick action tiles
          _QuickActionGrid(actions: [
            QuickAction(
              icon: Icons.flag,
              label: 'Reports Queue',
              badge: '12', // Pending count
              onTap: () => Navigator.push(ReportsQueueScreen()),
            ),
            QuickAction(
              icon: Icons.replay,
              label: 'Appeals',
              badge: '3',
              onTap: () => Navigator.push(AppealsQueueScreen()),
            ),
            QuickAction(
              icon: Icons.person_off,
              label: 'User Actions',
              onTap: () => Navigator.push(UserManagementScreen()),
            ),
            QuickAction(
              icon: Icons.history,
              label: 'History',
              onTap: () => Navigator.push(ModerationHistoryScreen()),
            ),
            QuickAction(
              icon: Icons.analytics,
              label: 'Analytics',
              onTap: () => Navigator.push(ModerationAnalyticsScreen()),
            ),
          ]),

          // Recent activity feed
          Expanded(child: _RecentActivityList()),
        ],
      ),
    );
  }
}
```

**Stats Overview**:
- Pending reports (total)
- Average resolution time (24h rolling)
- Reports resolved today
- Active restrictions/suspensions

#### Task 1.3: Migrate Existing Staff Tools to Moderation Space
**Priority**: HIGH
**Effort**: 6 hours
**Action**: Move `community_staff_tools_screen.dart` logic to new `reports_queue_screen.dart`

**Changes**:
```dart
// OLD: community/presentation/pages/community_staff_tools_screen.dart
// NEW: moderation/presentation/pages/reports_queue_screen.dart

// Keep all existing functionality:
// - Filter bar (status, target type, priority)
// - Report cards with actions
// - Pagination
// - Pull-to-refresh

// Add NEW features:
// - Bulk selection checkboxes
// - Bulk action toolbar (when items selected)
// - Save filter presets
```

---

### Phase 2: High Priority Features (Week 2)
**Goal**: Implement critical user-facing improvements

#### Task 2.1: Push Notifications for Report Updates
**Priority**: HIGH
**Effort**: 12 hours
**Dependencies**: FCM already configured in app

**Backend Changes** (`backend/src/community/reports/community-reports.service.ts`):
```typescript
import { NotificationsService } from '../notifications/notifications.service';

async reviewReport(reportId: string, decision: ReviewDecision) {
  const report = await this.prisma.communityReport.update({
    where: { id: reportId },
    data: {
      status: decision.action,
      reviewedById: decision.reviewerId,
      reviewedAt: new Date(),
      reviewNotes: decision.notes,
    },
    include: { reporter: true },
  });

  // Send notification to reporter
  if (report.reporter) {
    await this.notificationsService.sendPushNotification({
      userId: report.reporter.id,
      title: 'Report Update',
      body: `Your report has been ${decision.action}`,
      data: {
        type: 'REPORT_REVIEWED',
        reportId: report.id,
        action: decision.action,
      },
    });
  }

  return report;
}
```

**Mobile Changes** (`lib/services/notifications/notifications_store.dart`):
```dart
void _handleNotification(RemoteMessage message) {
  final data = message.data;

  if (data['type'] == 'REPORT_REVIEWED') {
    // Navigate to My Reports screen
    _navigationService.push('/community/my-reports');

    // Show in-app notification
    _showInAppNotification(
      title: message.notification?.title ?? 'Report Update',
      message: message.notification?.body ?? '',
      type: NotificationType.info,
    );
  }
}
```

**Acceptance Criteria**:
- [ ] Reporter receives push notification when report is reviewed
- [ ] Notification deep-links to My Reports screen
- [ ] In-app notification shown if app is open
- [ ] Notification includes action taken (approved/rejected/escalated)

#### Task 2.2: Appeal System
**Priority**: HIGH
**Effort**: 16 hours

**Database Schema** (add to `backend/prisma/schema.prisma`):
```prisma
model CommunityReportAppeal {
  id              String   @id @default(cuid())
  reportId        String
  report          CommunityReport @relation(fields: [reportId], references: [id], onDelete: Cascade)
  appealerId      String
  appealer        User     @relation("ReportAppeals", fields: [appealerId], references: [id])
  reason          String   @db.Text
  status          CommunityAppealStatus @default(pending)
  reviewedById    String?
  reviewedBy      User?    @relation("AppealReviews", fields: [reviewedById], references: [id])
  reviewedAt      DateTime?
  reviewNotes     String?  @db.Text
  decision        CommunityAppealDecision?
  createdAt       DateTime @default(now())
  updatedAt       DateTime @updatedAt

  @@index([appealerId])
  @@index([status])
  @@index([createdAt])
}

enum CommunityAppealStatus {
  pending
  under_review
  approved
  rejected
}

enum CommunityAppealDecision {
  overturn      // Original decision reversed
  uphold        // Original decision stands
  partial       // Modified action
}
```

**Backend API** (`backend/src/community/appeals/`):
```typescript
// New module: community-appeals.module.ts
// New controller: community-appeals.controller.ts
// New service: community-appeals.service.ts

@Controller('community/appeals')
export class CommunityAppealsController {
  @Post()
  @UseGuards(AuthGuard)
  async createAppeal(@CurrentUser() user, @Body() dto: CreateAppealDto) {
    // User can appeal their own report decisions
    return this.appealsService.createAppeal(user.id, dto);
  }

  @Get('queue')
  @UseGuards(AuthGuard, RolesGuard)
  @Roles(AppRole.COMMUNITY_ADMIN, AppRole.ADMIN, AppRole.OWNER)
  async getAppealsQueue(@Query() filters: AppealFiltersDto) {
    // Higher-level moderators review appeals
    return this.appealsService.getAppealsQueue(filters);
  }

  @Patch(':appealId/review')
  @UseGuards(AuthGuard, RolesGuard)
  @Roles(AppRole.COMMUNITY_ADMIN, AppRole.ADMIN, AppRole.OWNER)
  async reviewAppeal(
    @Param('appealId') appealId: string,
    @CurrentUser() user,
    @Body() decision: ReviewAppealDto,
  ) {
    return this.appealsService.reviewAppeal(appealId, user.id, decision);
  }
}
```

**Mobile UI** (`lib/features/community/presentation/pages/my_reports_screen.dart`):
```dart
// Add appeal button to rejected reports
if (report.status == 'rejected' && report.canAppeal) {
  TextButton.icon(
    icon: Icon(Icons.replay, size: 16),
    label: Text('Appeal Decision'),
    onPressed: () => _showAppealDialog(report),
  ),
}

Future<void> _showAppealDialog(CommunityReport report) async {
  final reason = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Appeal Report Decision'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Explain why you believe the decision was incorrect:'),
          SizedBox(height: 12),
          TextField(
            maxLines: 4,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: 'Your appeal reason...',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => reason = value,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, reason),
          child: Text('Submit Appeal'),
        ),
      ],
    ),
  );

  if (reason?.trim().isEmpty ?? true) return;

  await _reportsStore.submitAppeal(report.id, reason!);
}
```

**Acceptance Criteria**:
- [ ] Users can appeal rejected reports within 7 days
- [ ] Appeals appear in dedicated queue for community_admins
- [ ] Community admins can approve/reject/modify appeals
- [ ] Original moderator notified when their decision is appealed
- [ ] User notified of appeal outcome

---

### Phase 3: Medium Priority Features (Week 3)
**Goal**: Improve moderator efficiency and transparency

#### Task 3.1: Bulk Actions
**Priority**: MEDIUM
**Effort**: 10 hours

**Mobile UI** (`reports_queue_screen.dart`):
```dart
// Add selection mode
bool _isSelectionMode = false;
Set<String> _selectedReportIds = {};

// Add checkbox to report cards
if (_isSelectionMode) {
  Checkbox(
    value: _selectedReportIds.contains(report.id),
    onChanged: (checked) {
      setState(() {
        if (checked!) {
          _selectedReportIds.add(report.id);
        } else {
          _selectedReportIds.remove(report.id);
        }
      });
    },
  ),
}

// Add bulk action toolbar (shown when items selected)
if (_selectedReportIds.isNotEmpty) {
  Container(
    padding: EdgeInsets.all(12),
    color: AppColors.primary400.withValues(alpha: 0.1),
    child: Row(
      children: [
        Text('${_selectedReportIds.length} selected'),
        Spacer(),
        TextButton(
          onPressed: () => _bulkApprove(_selectedReportIds),
          child: Text('Approve All'),
        ),
        TextButton(
          onPressed: () => _bulkReject(_selectedReportIds),
          child: Text('Reject All'),
        ),
        IconButton(
          icon: Icon(Icons.clear),
          onPressed: () => setState(() {
            _selectedReportIds.clear();
            _isSelectionMode = false;
          }),
        ),
      ],
    ),
  ),
}
```

**Backend API**:
```typescript
@Post('bulk-review')
@UseGuards(AuthGuard, RolesGuard)
@Roles(AppRole.MODERATOR, AppRole.COMMUNITY_ADMIN)
async bulkReview(
  @CurrentUser() user,
  @Body() dto: BulkReviewDto,
) {
  // dto: { reportIds: string[], action: 'approve' | 'reject', notes?: string }
  const results = await Promise.allSettled(
    dto.reportIds.map(id =>
      this.reportsService.reviewReport(id, {
        action: dto.action,
        reviewerId: user.id,
        notes: dto.notes,
      })
    ),
  );

  return {
    success: results.filter(r => r.status === 'fulfilled').length,
    failed: results.filter(r => r.status === 'rejected').length,
    results,
  };
}
```

#### Task 3.2: Moderation History/Audit Log
**Priority**: MEDIUM
**Effort**: 12 hours

**Database Schema**:
```prisma
model ModerationAuditLog {
  id              String   @id @default(cuid())
  moderatorId     String
  moderator       User     @relation(fields: [moderatorId], references: [id])
  action          ModerationActionType
  targetType      String   // 'post', 'comment', 'user', 'report'
  targetId        String
  previousStatus  String?
  newStatus       String?
  reason          String?  @db.Text
  metadata        Json?    // Additional context
  createdAt       DateTime @default(now())

  @@index([moderatorId])
  @@index([action])
  @@index([targetType, targetId])
  @@index([createdAt])
}

enum ModerationActionType {
  hide_post
  archive_post
  restore_post
  hide_comment
  archive_comment
  restore_comment
  approve_report
  reject_report
  escalate_report
  suspend_user
  restrict_user
  ban_user
  lift_restriction
}
```

**Mobile UI** (`moderation_history_screen.dart`):
```dart
class ModerationHistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Moderation History')),
      body: Column(
        children: [
          // Filters
          _HistoryFilterBar(
            onFilterChanged: (filters) => _loadHistory(filters),
          ),

          // Audit log list
          Expanded(
            child: ListView.builder(
              itemCount: _historyItems.length,
              itemBuilder: (context, index) {
                final log = _historyItems[index];
                return _AuditLogCard(
                  moderatorName: log.moderator.name,
                  moderatorAvatar: log.moderator.imageUrl,
                  action: log.action,
                  targetType: log.targetType,
                  timestamp: log.createdAt,
                  reason: log.reason,
                  onTap: () => _showLogDetails(log),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

**Acceptance Criteria**:
- [ ] All moderation actions logged to audit table
- [ ] Moderators can view their own history
- [ ] Admins can view all moderator history
- [ ] Filterable by moderator, action type, date range
- [ ] Exportable to CSV for review

#### Task 3.3: Auto-Escalation Rules
**Priority**: MEDIUM
**Effort**: 14 hours

**Database Schema**:
```prisma
model AutoEscalationRule {
  id              String   @id @default(cuid())
  name            String
  description     String?
  isActive        Boolean  @default(true)
  conditions      Json     // { reportCount: 5, timeWindow: '24h', categories: ['harassment'] }
  action          String   // 'escalate' | 'auto_hide' | 'notify_admin'
  priority        Int      @default(0)
  createdById     String
  createdBy       User     @relation(fields: [createdById], references: [id])
  createdAt       DateTime @default(now())
  updatedAt       DateTime @updatedAt

  @@index([isActive])
}
```

**Backend Logic** (`backend/src/community/reports/auto-escalation.service.ts`):
```typescript
@Injectable()
export class AutoEscalationService {
  async checkEscalationRules(targetType: string, targetId: string) {
    const rules = await this.prisma.autoEscalationRule.findMany({
      where: { isActive: true },
      orderBy: { priority: 'desc' },
    });

    for (const rule of rules) {
      const conditions = rule.conditions as any;

      // Check if conditions met
      const reportCount = await this.prisma.communityReport.count({
        where: {
          targetType,
          targetId,
          status: 'pending',
          createdAt: {
            gte: this._parseTimeWindow(conditions.timeWindow),
          },
        },
      });

      if (reportCount >= conditions.reportCount) {
        await this._executeAction(rule.action, targetType, targetId);
      }
    }
  }

  private async _executeAction(action: string, targetType: string, targetId: string) {
    switch (action) {
      case 'escalate':
        await this.reportsService.escalateReports(targetType, targetId);
        break;
      case 'auto_hide':
        await this.contentService.hideContent(targetType, targetId, 'AUTO_ESCALATION');
        break;
      case 'notify_admin':
        await this.notificationsService.notifyAdmins({
          title: 'Auto-Escalation Triggered',
          body: `${targetType} ${targetId} has ${reportCount} reports`,
        });
        break;
    }
  }
}
```

**Mobile UI** (Admin Console only - `console/app/(protected)/moderation-settings/page.tsx`):
```tsx
'use client';

export default function ModerationSettingsPage() {
  const [rules, setRules] = useState<EscalationRule[]>([]);

  return (
    <div>
      <h1>Auto-Escalation Rules</h1>

      <RulesTable rules={rules} />

      <Button onClick={() => setDialogOpen(true)}>
        Add New Rule
      </Button>

      <RuleEditorDialog
        open={dialogOpen}
        onClose={() => setDialogOpen(false)}
        onSave={(rule) => createRule(rule)}
      />
    </div>
  );
}
```

#### Task 3.4: Profile Report Moderation
**Priority**: MEDIUM
**Effort**: 8 hours

**Extend Existing Models**:
```dart
// Already exists: CommunityReportTargetType includes 'userProfile'
// Add to reports queue filters
_DropdownField<String>(
  label: 'TARGET',
  value: _targetTypeFilter,
  items: [
    'All Targets',
    'Posts',
    'Comments',
    'Profiles', // ← Add this
    'Messages',
  ],
  onChanged: (value) => setState(() => _targetTypeFilter = value),
),
```

**Backend**: Already supported - just needs frontend UI

---

### Phase 4: Low Priority Enhancements (Week 4+)
**Goal**: Advanced features for scale

#### Task 4.1: Automated Content Filtering (ML Integration)
**Priority**: LOW
**Effort**: 20 hours
**Dependencies**: Requires ML service or third-party API

**Options**:
1. **OpenAI Moderation API**: Fast, cheap, good accuracy
2. **Perspective API (Google)**: Free, toxicity detection
3. **AWS Comprehend**: Sentiment analysis
4. **Custom ML Model**: Maximum control, high effort

**Recommended**: Start with Perspective API (free tier)

**Backend Integration**:
```typescript
import { Injectable } from '@nestjs/common';
import axios from 'axios';

@Injectable()
export class ContentFilterService {
  private perspectiveApiKey = process.env.PERSPECTIVE_API_KEY;

  async analyzeContent(text: string): Promise<ToxicityScore> {
    const response = await axios.post(
      'https://commentanalyzer.googleapis.com/v1alpha1/comments:analyze',
      {
        comment: { text },
        languages: ['en'],
        requestedAttributes: {
          TOXICITY: {},
          SEVERE_TOXICITY: {},
          IDENTITY_ATTACK: {},
          INSULT: {},
          THREAT: {},
          SEXUALLY_EXPLICIT: {},
        },
      },
      {
        params: { key: this.perspectiveApiKey },
      },
    );

    return {
      toxicity: response.data.attributeScores.TOXICITY.summaryScore.value,
      severeToxicity: response.data.attributeScores.SEVERE_TOXICITY.summaryScore.value,
      identityAttack: response.data.attributeScores.IDENTITY_ATTACK.summaryScore.value,
      insult: response.data.attributeScores.INSULT.summaryScore.value,
      threat: response.data.attributeScores.THREAT.summaryScore.value,
      sexuallyExplicit: response.data.attributeScores.SEXUALLY_EXPLICIT.summaryScore.value,
    };
  }

  shouldAutoFlag(scores: ToxicityScore): boolean {
    return (
      scores.severeToxicity > 0.8 ||
      scores.threat > 0.7 ||
      scores.identityAttack > 0.7
    );
  }
}
```

**Integration Points**:
```typescript
// In posts.service.ts
async createPost(userId: string, content: string) {
  // Analyze content before posting
  const toxicityScores = await this.contentFilterService.analyzeContent(content);

  if (this.contentFilterService.shouldAutoFlag(toxicityScores)) {
    // Auto-hide and create report
    const post = await this.prisma.communityPost.create({
      data: {
        authorId: userId,
        content,
        status: CommunityContentModerationStatus.hidden,
      },
    });

    await this.reportsService.createAutoReport({
      targetType: 'communityPost',
      targetId: post.id,
      reason: 'Automated toxicity detection',
      metadata: { toxicityScores },
    });

    return post;
  }

  // Normal post creation
  return this.prisma.communityPost.create({
    data: { authorId: userId, content },
  });
}
```

**Acceptance Criteria**:
- [ ] Highly toxic content auto-hidden on submission
- [ ] Auto-report created for moderator review
- [ ] User notified their content is under review
- [ ] Moderator can override AI decision

#### Task 4.2: Queue Prioritization Algorithm
**Priority**: LOW
**Effort**: 10 hours

**Scoring Algorithm**:
```typescript
interface ReportPriorityScore {
  reportId: string;
  score: number;
  factors: {
    age: number;           // Older = higher priority
    severity: number;      // Category weight
    reporterRep: number;   // Reporter reliability
    reportCount: number;   // Multiple reports = higher
    targetAuthorRep: number; // Low rep target = higher
  };
}

function calculatePriority(report: CommunityReport): number {
  const ageHours = (Date.now() - report.createdAt.getTime()) / (1000 * 60 * 60);
  const ageFactor = Math.min(ageHours / 24, 1); // Max 1.0 at 24h

  const severityWeights = {
    harassment: 1.0,
    hate_speech: 1.0,
    violence: 0.9,
    spam: 0.3,
    misinformation: 0.6,
    other: 0.2,
  };
  const severityFactor = severityWeights[report.category] || 0.5;

  const reporterRepFactor = report.reporter.reportAccuracyRate || 0.5;

  const reportCountFactor = Math.min(
    await countSimilarReports(report.targetType, report.targetId) / 10,
    1.0,
  );

  const targetAuthorRepFactor = 1 - (report.target.author.reputationScore || 0.5);

  return (
    ageFactor * 0.2 +
    severityFactor * 0.3 +
    reporterRepFactor * 0.15 +
    reportCountFactor * 0.25 +
    targetAuthorRepFactor * 0.1
  );
}
```

**Mobile UI**:
```dart
// Add sort dropdown to filter bar
_DropdownField<String>(
  label: 'SORT BY',
  value: _sortBy,
  items: [
    'Priority Score',
    'Newest First',
    'Oldest First',
    'Most Reports',
  ],
  onChanged: (value) {
    setState(() => _sortBy = value);
    _loadReports();
  },
),
```

#### Task 4.3: User Reputation System
**Priority**: LOW
**Effort**: 16 hours

**Database Schema**:
```prisma
model UserReputationScore {
  id              String   @id @default(cuid())
  userId          String   @unique
  user            User     @relation(fields: [userId], references: [id])

  // Report accuracy (as reporter)
  reportsSubmitted      Int @default(0)
  reportsApproved       Int @default(0)
  reportsRejected       Int @default(0)
  reportAccuracyRate    Float @default(0.5) // approved / total

  // Content quality (as author)
  postsCreated          Int @default(0)
  postsHidden           Int @default(0)
  postsArchived         Int @default(0)
  contentQualityRate    Float @default(1.0) // 1 - (moderated / total)

  // Overall reputation
  overallScore          Float @default(0.5) // 0-1 scale
  trustLevel            UserTrustLevel @default(neutral)

  updatedAt       DateTime @updatedAt

  @@index([overallScore])
  @@index([trustLevel])
}

enum UserTrustLevel {
  suspicious    // Score < 0.3 - flagged for review
  neutral       // Score 0.3-0.7 - normal user
  trusted       // Score 0.7-0.9 - reliable
  verified      // Score > 0.9 - highly trusted
}
```

**Calculation Logic**:
```typescript
async updateReputationScore(userId: string) {
  const stats = await this._getUserStats(userId);

  const reportAccuracy = stats.reportsSubmitted > 0
    ? stats.reportsApproved / stats.reportsSubmitted
    : 0.5;

  const contentQuality = stats.postsCreated > 0
    ? 1 - ((stats.postsHidden + stats.postsArchived) / stats.postsCreated)
    : 1.0;

  const overallScore = (reportAccuracy * 0.4) + (contentQuality * 0.6);

  const trustLevel =
    overallScore >= 0.9 ? UserTrustLevel.verified :
    overallScore >= 0.7 ? UserTrustLevel.trusted :
    overallScore >= 0.3 ? UserTrustLevel.neutral :
    UserTrustLevel.suspicious;

  await this.prisma.userReputationScore.upsert({
    where: { userId },
    update: {
      reportAccuracyRate: reportAccuracy,
      contentQualityRate: contentQuality,
      overallScore,
      trustLevel,
      ...stats,
    },
    create: {
      userId,
      reportAccuracyRate: reportAccuracy,
      contentQualityRate: contentQuality,
      overallScore,
      trustLevel,
      ...stats,
    },
  });
}
```

**Mobile UI** (Display in profile):
```dart
// In public_profile_screen.dart
if (user.reputationScore != null) {
  Container(
    padding: EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: _getTrustLevelColor(user.trustLevel).withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        Icon(
          _getTrustLevelIcon(user.trustLevel),
          size: 16,
          color: _getTrustLevelColor(user.trustLevel),
        ),
        SizedBox(width: 6),
        Text(
          user.trustLevel.toUpperCase(),
          style: AppTypography.custom(
            size: 11,
            weight: FontWeight.w700,
            color: _getTrustLevelColor(user.trustLevel),
          ),
        ),
      ],
    ),
  ),
}
```

---

## Detailed File Structure

### New Files to Create

**Backend**:
```
backend/src/
├── community/
│   ├── appeals/
│   │   ├── community-appeals.module.ts
│   │   ├── community-appeals.controller.ts
│   │   ├── community-appeals.service.ts
│   │   └── dto/
│   │       ├── create-appeal.dto.ts
│   │       ├── review-appeal.dto.ts
│   │       └── appeal-response.dto.ts
│   ├── reports/
│   │   ├── auto-escalation.service.ts        # NEW
│   │   └── content-filter.service.ts         # NEW
│   └── moderation/
│       ├── moderation-audit.service.ts       # NEW
│       └── user-reputation.service.ts        # NEW
```

**Mobile**:
```
lib/features/
├── moderation/                                # NEW MODULE
│   ├── data/
│   │   └── models/
│   │       ├── moderation_audit_log_model.dart
│   │       ├── appeal_model.dart
│   │       └── user_reputation_model.dart
│   ├── presentation/
│   │   ├── pages/
│   │   │   ├── moderation_hub_screen.dart
│   │   │   ├── reports_queue_screen.dart     # Migrated from community
│   │   │   ├── appeals_queue_screen.dart
│   │   │   ├── user_management_screen.dart
│   │   │   ├── moderation_history_screen.dart
│   │   │   └── moderation_analytics_screen.dart
│   │   └── widgets/
│   │       ├── moderation_nav_rail.dart
│   │       ├── queue_filter_bar.dart
│   │       ├── bulk_action_toolbar.dart
│   │       ├── moderation_stats_card.dart
│   │       └── audit_log_card.dart
│   └── application/
│       └── moderation_store.dart
└── community/
    └── presentation/
        └── pages/
            └── community_staff_tools_screen.dart  # DEPRECATED - remove after migration
```

**Console** (Admin-only features):
```
console/app/(protected)/
├── moderation-settings/
│   ├── page.tsx                               # Auto-escalation rules
│   └── _components/
│       ├── RulesTable.tsx
│       └── RuleEditorDialog.tsx
└── moderation-analytics/
    ├── page.tsx                               # Performance dashboard
    └── _components/
        ├── ModeratorPerformanceChart.tsx
        ├── ViolationTrendsChart.tsx
        └── ResolutionTimeChart.tsx
```

---

## Testing Plan

### Unit Tests
**Backend**:
- `community-appeals.service.spec.ts` - Appeal creation, review logic
- `auto-escalation.service.spec.ts` - Rule evaluation, action execution
- `content-filter.service.spec.ts` - Toxicity scoring, thresholds
- `user-reputation.service.spec.ts` - Score calculation, trust levels

**Mobile**:
- `moderation_store_test.dart` - State management
- `reports_queue_screen_test.dart` - UI interactions
- `bulk_action_toolbar_test.dart` - Selection logic

### Integration Tests
**Backend**:
- Appeal workflow: Create → Review → Notification
- Auto-escalation: Multiple reports → Rule trigger → Auto-hide
- Bulk actions: Select reports → Bulk approve → Audit log

**Mobile**:
- Report submission → Appeal → Notification → My Reports update
- Moderation action → Audit log entry → History screen display

### E2E Tests (Cypress for Console)
- Moderator reviews report queue
- Admin configures auto-escalation rule
- User appeals rejected report
- Moderator performs bulk actions

---

## Migration Strategy

### Phase 1: Parallel Development (Week 1-2)
- Build new Moderation Space alongside existing Staff Tools
- Both interfaces functional during development
- No breaking changes to existing flows

### Phase 2: Beta Testing (Week 3)
- Enable Moderation Space for dev/owner roles only
- Collect feedback on workflow efficiency
- Fix bugs and refine UI

### Phase 3: Gradual Rollout (Week 4)
- Enable for all moderators
- Show migration banner in old Staff Tools: "Try the new Moderation Space!"
- Monitor adoption metrics

### Phase 4: Deprecation (Week 5+)
- Remove old Staff Tools screen
- Redirect old route to new Moderation Hub
- Update documentation

---

## Success Metrics

### Efficiency Metrics
- **Average time to resolve report**: Target < 2 hours (from 4+ hours currently)
- **Reports resolved per moderator per day**: Target 20+ (from ~10 currently)
- **Appeal response time**: Target < 24 hours

### Quality Metrics
- **Appeal overturn rate**: Target < 10% (indicates good initial decisions)
- **User satisfaction with moderation**: Survey after resolution (target 4/5 stars)
- **False positive rate**: Auto-filter accuracy > 90%

### Scale Metrics
- **Reports backlog**: Target < 50 pending at any time
- **Moderator utilization**: Target 60-80% of time spent on reviews (vs admin tasks)
- **Auto-escalation hit rate**: Target 80% of rules successfully catching issues

---

## Risk Mitigation

### Risk 1: Moderator Training Required
**Mitigation**:
- Create video walkthrough of new Moderation Space
- Add in-app tooltips for first-time users
- Schedule training session for moderator team

### Risk 2: Backend Performance Under Load
**Mitigation**:
- Add database indexes for report queries (already planned)
- Implement pagination with cursor-based approach
- Add Redis caching for queue counts/stats

### Risk 3: False Positives from Auto-Filter
**Mitigation**:
- Start with conservative thresholds (e.g., 0.9 instead of 0.7)
- All auto-hidden content goes to review queue
- Track false positive rate and adjust

### Risk 4: Appeals Overwhelming Admins
**Mitigation**:
- Limit appeals to 1 per report
- 7-day window to submit appeal (prevents old reports)
- Auto-reject spam appeals (same reason repeated)

---

## Resource Requirements

### Development
- **Backend**: 60 hours (1.5 weeks full-time)
- **Mobile**: 80 hours (2 weeks full-time)
- **Console**: 20 hours (0.5 weeks full-time)
- **Testing**: 20 hours
- **Total**: ~180 hours (~4-5 weeks for 1 developer)

### Infrastructure
- **Database**: Minimal increase (new tables fit in current tier)
- **API Costs**:
  - Perspective API: Free tier (10,000 requests/day)
  - FCM Push: Free (unlimited)
- **Storage**: +50MB for audit logs (negligible)

### Ongoing Maintenance
- **Moderator onboarding**: 1 hour per new moderator
- **Rule tuning**: 2 hours/month (adjust auto-escalation thresholds)
- **Performance monitoring**: 1 hour/week (check metrics dashboard)

---

## Rollout Timeline

| Week | Phase | Deliverables |
|------|-------|--------------|
| **Week 1** | Foundation | - Backend status field verified<br>- Moderation Space navigation added<br>- Hub dashboard UI complete<br>- Reports queue migrated |
| **Week 2** | High Priority | - Push notifications working<br>- Appeal system backend + UI<br>- Testing and bug fixes |
| **Week 3** | Medium Priority | - Bulk actions implemented<br>- Audit log backend + UI<br>- Auto-escalation rules (backend) |
| **Week 4** | Low Priority + Polish | - Content filter integration<br>- Queue prioritization<br>- Analytics dashboard (console)<br>- Beta testing with moderators |
| **Week 5** | Launch | - User reputation system<br>- Training materials created<br>- Gradual rollout to all moderators<br>- Monitor metrics |
| **Week 6+** | Iteration | - Collect feedback<br>- Refine based on usage patterns<br>- Deprecate old Staff Tools |

---

## Conclusion

This plan takes the Blocnet moderation system from functional to **world-class**:

✅ **Strategic**: Dedicated Moderation Space separates governance from social features
✅ **Efficient**: Bulk actions, prioritization, and auto-escalation reduce moderator workload by 50%+
✅ **Transparent**: Audit logs and analytics build trust with users and admins
✅ **Fair**: Appeal system gives users recourse, reducing frustration
✅ **Scalable**: Auto-filtering and reputation system prepare for 10x growth

**Recommended Start**: Begin with **Phase 0 (Critical Foundation)** immediately, then move to **Phase 1 (Moderation Space)** to establish the new architecture. This foundation will make all subsequent features easier to integrate.

**Next Steps**:
1. ✅ Review and approve this plan
2. ✅ Confirm backend status field (Task 0.1)
3. ✅ Create Moderation Space navigation (Task 1.1)
4. ✅ Begin migration of Staff Tools to Reports Queue (Task 1.3)
