# Implementation Guide: User Mentions, Blocking, and Account Deactivation

This guide provides step-by-step instructions for implementing three key features:
1. User tagging (@mentions) in comments and community posts
2. User blocking functionality
3. Account deactivation

---

## Feature 1: User Tagging (@mentions)

### Backend Implementation (NestJS)

#### Step 1: Update Prisma Schema

Add to `backend/prisma/schema.prisma`:

```prisma
model User {
  // ... existing fields
  username          String?   @unique
  mentions          Mention[] @relation("MentionedUser")
  createdMentions   Mention[] @relation("MentionCreator")
  // ... rest of fields
}

model Comment {
  // ... existing fields
  mentions    Mention[]
  // ... rest of fields
}

model CommunityPost {
  // ... existing fields
  mentions    Mention[]
  // ... rest of fields
}

model Mention {
  id              String        @id @default(uuid())
  mentionedUserId String        @map("mentioned_user_id")
  creatorId       String        @map("creator_id")
  commentId       String?       @map("comment_id")
  postId          String?       @map("post_id")
  createdAt       DateTime      @default(now()) @map("created_at")

  mentionedUser   User          @relation("MentionedUser", fields: [mentionedUserId], references: [id], onDelete: Cascade)
  creator         User          @relation("MentionCreator", fields: [creatorId], references: [id], onDelete: Cascade)
  comment         Comment?      @relation(fields: [commentId], references: [id], onDelete: Cascade)
  post            CommunityPost? @relation(fields: [postId], references: [id], onDelete: Cascade)

  @@map("mentions")
  @@index([mentionedUserId])
  @@index([creatorId])
  @@index([commentId])
  @@index([postId])
}
```

#### Step 2: Run Migration

```bash
cd backend
bunx prisma migrate dev --name add_mentions_table
```

#### Step 3: Create Mentions Module

Create `backend/src/mentions/mentions.module.ts`:

```typescript
import { Module } from '@nestjs/common';
import { MentionsService } from './mentions.service';
import { MentionsController } from './mentions.controller';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [MentionsController],
  providers: [MentionsService],
  exports: [MentionsService],
})
export class MentionsModule {}
```

#### Step 4: Create Mentions Service

Create `backend/src/mentions/mentions.service.ts`:

```typescript
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class MentionsService {
  constructor(private prisma: PrismaService) {}

  async extractMentions(text: string): Promise<string[]> {
    const mentionRegex = /@(\w+)/g;
    const matches = text.match(mentionRegex);
    if (!matches) return [];
    return matches.map(m => m.substring(1)); // Remove @ symbol
  }

  async createMentions(data: {
    text: string;
    creatorId: string;
    commentId?: string;
    postId?: string;
  }) {
    const usernames = await this.extractMentions(data.text);
    if (usernames.length === 0) return [];

    // Find users by username
    const users = await this.prisma.user.findMany({
      where: {
        username: {
          in: usernames,
        },
      },
      select: { id: true },
    });

    // Create mentions
    const mentions = await Promise.all(
      users.map(user =>
        this.prisma.mention.create({
          data: {
            mentionedUserId: user.id,
            creatorId: data.creatorId,
            commentId: data.commentId,
            postId: data.postId,
          },
        }),
      ),
    );

    return mentions;
  }

  async searchUsers(query: string, limit = 10) {
    return this.prisma.user.findMany({
      where: {
        OR: [
          { username: { contains: query, mode: 'insensitive' } },
          { display_name: { contains: query, mode: 'insensitive' } },
        ],
      },
      select: {
        id: true,
        username: true,
        display_name: true,
        avatar_url: true,
      },
      take: limit,
    });
  }
}
```

#### Step 5: Create Mentions Controller

Create `backend/src/mentions/mentions.controller.ts`:

```typescript
import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { MentionsService } from './mentions.service';
import { AuthGuard } from '../auth/auth.guard';

@Controller('mentions')
@UseGuards(AuthGuard)
export class MentionsController {
  constructor(private mentionsService: MentionsService) {}

  @Get('search-users')
  async searchUsers(@Query('q') query: string) {
    if (!query || query.length < 2) {
      return [];
    }
    return this.mentionsService.searchUsers(query);
  }
}
```

#### Step 6: Update Comments/Posts Services

In `backend/src/comments/comments.service.ts` and `backend/src/community-posts/community-posts.service.ts`, add mention creation:

```typescript
import { MentionsService } from '../mentions/mentions.service';

export class CommentsService {
  constructor(
    private prisma: PrismaService,
    private mentionsService: MentionsService, // Inject this
  ) {}

  async create(createCommentDto: CreateCommentDto, userId: string) {
    const comment = await this.prisma.comment.create({
      data: {
        // ... existing fields
      },
    });

    // Create mentions
    await this.mentionsService.createMentions({
      text: createCommentDto.content,
      creatorId: userId,
      commentId: comment.id,
    });

    return comment;
  }
}
```

#### Step 7: Add Notification for Mentions

Update `backend/src/notifications/notifications.service.ts`:

Add to NotificationType enum:
```typescript
user_mentioned
```

Create notification when mention is created:
```typescript
async notifyMention(mentionId: string) {
  const mention = await this.prisma.mention.findUnique({
    where: { id: mentionId },
    include: {
      creator: true,
      comment: true,
      post: true,
    },
  });

  if (!mention) return;

  await this.create({
    userId: mention.mentionedUserId,
    type: 'user_mentioned',
    category: 'social',
    message: `${mention.creator.display_name || mention.creator.username} mentioned you`,
    // ... add relevant metadata
  });
}
```

### Frontend Implementation (Flutter)

#### Step 1: Create Mention Input Widget

Create `mobile/lib/shared/widgets/mention_text_field.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';

class MentionTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final Function(List<String> mentions) onMentionsChanged;
  final int? maxLines;

  const MentionTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onMentionsChanged,
    this.maxLines,
  });

  @override
  State<MentionTextField> createState() => _MentionTextFieldState();
}

class _MentionTextFieldState extends State<MentionTextField> {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  List<Map<String, dynamic>> _suggestedUsers = [];
  String _currentMentionQuery = '';

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _removeOverlay();
    super.dispose();
  }

  void _onTextChanged() {
    final text = widget.controller.text;
    final selection = widget.controller.selection;

    // Extract current word at cursor
    final textBeforeCursor = text.substring(0, selection.baseOffset);
    final words = textBeforeCursor.split(RegExp(r'\s'));
    final currentWord = words.isNotEmpty ? words.last : '';

    if (currentWord.startsWith('@') && currentWord.length > 1) {
      _currentMentionQuery = currentWord.substring(1);
      _searchUsers(_currentMentionQuery);
    } else {
      _removeOverlay();
    }

    // Extract all mentions
    final mentionRegex = RegExp(r'@(\w+)');
    final matches = mentionRegex.allMatches(text);
    final mentions = matches.map((m) => m.group(1)!).toList();
    widget.onMentionsChanged(mentions);
  }

  Future<void> _searchUsers(String query) async {
    // TODO: Call API to search users
    // final users = await apiClient.get('/mentions/search-users?q=$query');
    // setState(() {
    //   _suggestedUsers = users;
    //   _showOverlay();
    // });
  }

  void _showOverlay() {
    _removeOverlay();
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height),
          child: Material(
            elevation: 4,
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _suggestedUsers.length,
                itemBuilder: (context, index) {
                  final user = _suggestedUsers[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: user['avatar_url'] != null
                          ? NetworkImage(user['avatar_url'])
                          : null,
                      child: user['avatar_url'] == null
                          ? Text(user['username'][0].toUpperCase())
                          : null,
                    ),
                    title: Text(
                      user['display_name'] ?? user['username'],
                      style: AppTypography.custom(
                        color: AppColors.textPrimary,
                        size: 14,
                        weight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      '@${user['username']}',
                      style: AppTypography.custom(
                        color: AppColors.textMuted,
                        size: 12,
                        weight: FontWeight.w400,
                      ),
                    ),
                    onTap: () => _insertMention(user['username']),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _insertMention(String username) {
    final text = widget.controller.text;
    final selection = widget.controller.selection;
    final textBeforeCursor = text.substring(0, selection.baseOffset);
    final textAfterCursor = text.substring(selection.baseOffset);

    // Replace @query with @username
    final words = textBeforeCursor.split(RegExp(r'\s'));
    words[words.length - 1] = '@$username ';
    final newTextBefore = words.join(' ');

    widget.controller.text = newTextBefore + textAfterCursor;
    widget.controller.selection = TextSelection.fromPosition(
      TextPosition(offset: newTextBefore.length),
    );

    _removeOverlay();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: widget.controller,
        maxLines: widget.maxLines,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: AppTypography.custom(
            color: AppColors.textFaint,
            size: 14,
            weight: FontWeight.w400,
          ),
          filled: true,
          fillColor: AppColors.bgBase,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.borderSubtle),
          ),
        ),
        style: AppTypography.custom(
          color: AppColors.textPrimary,
          size: 14,
          weight: FontWeight.w400,
        ),
      ),
    );
  }
}
```

#### Step 2: Create Mention Display Widget

Create `mobile/lib/shared/widgets/mention_text.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:blocnet/app/theme.dart';

class MentionText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Function(String username)? onMentionTap;

  const MentionText({
    super.key,
    required this.text,
    this.style,
    this.onMentionTap,
  });

  @override
  Widget build(BuildContext context) {
    final spans = _buildTextSpans(text);
    return RichText(
      text: TextSpan(
        children: spans,
        style: style ?? TextStyle(color: AppColors.textPrimary),
      ),
    );
  }

  List<TextSpan> _buildTextSpans(String text) {
    final regex = RegExp(r'@(\w+)');
    final matches = regex.allMatches(text);

    if (matches.isEmpty) {
      return [TextSpan(text: text)];
    }

    final spans = <TextSpan>[];
    int lastEnd = 0;

    for (final match in matches) {
      // Add text before mention
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }

      // Add mention
      final username = match.group(1)!;
      spans.add(
        TextSpan(
          text: '@$username',
          style: TextStyle(
            color: AppColors.primary400,
            fontWeight: FontWeight.w600,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () => onMentionTap?.call(username),
        ),
      );

      lastEnd = match.end;
    }

    // Add remaining text
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    return spans;
  }
}
```

---

## Feature 2: User Blocking

### Backend Implementation

#### Step 1: Update Prisma Schema

```prisma
model UserBlock {
  id          String   @id @default(uuid())
  blockerId   String   @map("blocker_id")
  blockedId   String   @map("blocked_id")
  createdAt   DateTime @default(now()) @map("created_at")

  blocker     User     @relation("Blocker", fields: [blockerId], references: [id], onDelete: Cascade)
  blocked     User     @relation("Blocked", fields: [blockedId], references: [id], onDelete: Cascade)

  @@unique([blockerId, blockedId])
  @@map("user_blocks")
  @@index([blockerId])
  @@index([blockedId])
}

model User {
  // ... existing fields
  blocking    UserBlock[] @relation("Blocker")
  blockedBy   UserBlock[] @relation("Blocked")
  // ... rest
}
```

#### Step 2: Run Migration

```bash
bunx prisma migrate dev --name add_user_blocks
```

#### Step 3: Create User Blocks Module

Create `backend/src/user-blocks/user-blocks.service.ts`:

```typescript
import { Injectable, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class UserBlocksService {
  constructor(private prisma: PrismaService) {}

  async blockUser(blockerId: string, blockedId: string) {
    if (blockerId === blockedId) {
      throw new BadRequestException('You cannot block yourself');
    }

    return this.prisma.userBlock.create({
      data: {
        blockerId,
        blockedId,
      },
    });
  }

  async unblockUser(blockerId: string, blockedId: string) {
    return this.prisma.userBlock.deleteMany({
      where: {
        blockerId,
        blockedId,
      },
    });
  }

  async getBlockedUsers(userId: string) {
    const blocks = await this.prisma.userBlock.findMany({
      where: { blockerId: userId },
      include: {
        blocked: {
          select: {
            id: true,
            username: true,
            display_name: true,
            avatar_url: true,
          },
        },
      },
    });

    return blocks.map(b => b.blocked);
  }

  async isBlocked(blockerId: string, blockedId: string): Promise<boolean> {
    const block = await this.prisma.userBlock.findUnique({
      where: {
        blockerId_blockedId: {
          blockerId,
          blockedId,
        },
      },
    });

    return !!block;
  }

  async getBlockedUserIds(userId: string): Promise<string[]> {
    const blocks = await this.prisma.userBlock.findMany({
      where: { blockerId: userId },
      select: { blockedId: true },
    });

    return blocks.map(b => b.blockedId);
  }
}
```

#### Step 4: Create Controller

Create `backend/src/user-blocks/user-blocks.controller.ts`:

```typescript
import { Controller, Post, Delete, Get, Param, UseGuards } from '@nestjs/common';
import { UserBlocksService } from './user-blocks.service';
import { AuthGuard } from '../auth/auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';

@Controller('user-blocks')
@UseGuards(AuthGuard)
export class UserBlocksController {
  constructor(private userBlocksService: UserBlocksService) {}

  @Post(':userId/block')
  async blockUser(
    @CurrentUser('id') currentUserId: string,
    @Param('userId') blockedId: string,
  ) {
    return this.userBlocksService.blockUser(currentUserId, blockedId);
  }

  @Delete(':userId/unblock')
  async unblockUser(
    @CurrentUser('id') currentUserId: string,
    @Param('userId') blockedId: string,
  ) {
    return this.userBlocksService.unblockUser(currentUserId, blockedId);
  }

  @Get('blocked-users')
  async getBlockedUsers(@CurrentUser('id') userId: string) {
    return this.userBlocksService.getBlockedUsers(userId);
  }
}
```

#### Step 5: Filter Blocked Users in Feeds

Update services to filter blocked users:

```typescript
// In projects.service.ts, updates.service.ts, community-posts.service.ts, etc.
async findAll(userId?: string) {
  let blockedUserIds: string[] = [];

  if (userId) {
    blockedUserIds = await this.userBlocksService.getBlockedUserIds(userId);
  }

  return this.prisma.project.findMany({
    where: {
      // Exclude blocked users' content
      adminId: {
        notIn: blockedUserIds,
      },
    },
  });
}
```

### Frontend Implementation

#### Step 1: Create Block/Unblock API Methods

Add to `mobile/lib/services/api/api_client.dart`:

```dart
Future<void> blockUser(String userId) async {
  await post('/user-blocks/$userId/block', {});
}

Future<void> unblockUser(String userId) async {
  await delete('/user-blocks/$userId/unblock');
}

Future<List<dynamic>> getBlockedUsers() async {
  final response = await get('/user-blocks/blocked-users');
  return response.data as List<dynamic>;
}
```

#### Step 2: Add Block Button to User Profiles

In user profile screens, add:

```dart
IconButton(
  icon: Icon(
    isBlocked ? Icons.block : Icons.block_outlined,
    color: isBlocked ? AppColors.error500 : AppColors.textMuted,
  ),
  onPressed: () async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgSurface,
        title: Text(
          isBlocked ? 'Unblock User?' : 'Block User?',
          style: AppTypography.custom(
            color: AppColors.textPrimary,
            size: 18,
            weight: FontWeight.w600,
          ),
        ),
        content: Text(
          isBlocked
              ? 'You will see their content again.'
              : 'You will no longer see their content.',
          style: AppTypography.custom(
            color: AppColors.textSecondary,
            size: 14,
            weight: FontWeight.w400,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              isBlocked ? 'Unblock' : 'Block',
              style: TextStyle(color: AppColors.error500),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (isBlocked) {
        await apiClient.unblockUser(userId);
      } else {
        await apiClient.blockUser(userId);
      }
      // Refresh UI
    }
  },
)
```

#### Step 3: Add Blocked Users List in Settings

Create `mobile/lib/screen/blocked_users_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  List<dynamic> blockedUsers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    // TODO: Call API
    // final users = await apiClient.getBlockedUsers();
    // setState(() {
    //   blockedUsers = users;
    //   isLoading = false;
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: const CustomAppBar(
        title: 'Blocked Users',
        backButton: true,
        showSearch: false,
        showFilter: false,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : blockedUsers.isEmpty
              ? Center(
                  child: Text(
                    'No blocked users',
                    style: AppTypography.custom(
                      color: AppColors.textMuted,
                      size: 14,
                      weight: FontWeight.w400,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: blockedUsers.length,
                  itemBuilder: (context, index) {
                    final user = blockedUsers[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: user['avatar_url'] != null
                            ? NetworkImage(user['avatar_url'])
                            : null,
                      ),
                      title: Text(
                        user['display_name'] ?? user['username'],
                        style: AppTypography.custom(
                          color: AppColors.textPrimary,
                          size: 14,
                          weight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        '@${user['username']}',
                        style: AppTypography.custom(
                          color: AppColors.textMuted,
                          size: 12,
                          weight: FontWeight.w400,
                        ),
                      ),
                      trailing: TextButton(
                        onPressed: () async {
                          // await apiClient.unblockUser(user['id']);
                          _loadBlockedUsers();
                        },
                        child: Text('Unblock'),
                      ),
                    );
                  },
                ),
    );
  }
}
```

---

## Feature 3: Account Deactivation

### Backend Implementation

#### Step 1: Update Prisma Schema

```prisma
model User {
  // ... existing fields
  isActive      Boolean  @default(true) @map("is_active")
  deactivatedAt DateTime? @map("deactivated_at")
  // ... rest
}
```

#### Step 2: Run Migration

```bash
bunx prisma migrate dev --name add_user_active_status
```

#### Step 3: Add Deactivation Endpoint

In `backend/src/users/users.service.ts`:

```typescript
async deactivateAccount(userId: string) {
  return this.prisma.user.update({
    where: { id: userId },
    data: {
      isActive: false,
      deactivatedAt: new Date(),
    },
  });
}

async reactivateAccount(userId: string) {
  return this.prisma.user.update({
    where: { id: userId },
    data: {
      isActive: true,
      deactivatedAt: null,
    },
  });
}
```

In `backend/src/users/users.controller.ts`:

```typescript
@Post('deactivate')
@UseGuards(AuthGuard)
async deactivateAccount(@CurrentUser('id') userId: string) {
  await this.usersService.deactivateAccount(userId);
  return { message: 'Account deactivated successfully' };
}

@Post('reactivate')
@UseGuards(AuthGuard)
async reactivateAccount(@CurrentUser('id') userId: string) {
  await this.usersService.reactivateAccount(userId);
  return { message: 'Account reactivated successfully' };
}
```

#### Step 4: Filter Deactivated Users

Update AuthGuard to check if user is active:

```typescript
@Injectable()
export class AuthGuard implements CanActivate {
  async canActivate(context: ExecutionContext): Promise<boolean> {
    // ... existing auth logic

    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user || !user.isActive) {
      throw new UnauthorizedException('Account is deactivated');
    }

    // ... rest
  }
}
```

### Frontend Implementation

#### Step 1: Add Deactivation Screen

Create `mobile/lib/screen/deactivate_account_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';

class DeactivateAccountScreen extends StatelessWidget {
  const DeactivateAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: const CustomAppBar(
        title: 'Deactivate Account',
        backButton: true,
        showSearch: false,
        showFilter: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 64,
              color: AppColors.warning500,
            ),
            const SizedBox(height: 24),
            Text(
              'Are you sure you want to deactivate your account?',
              style: AppTypography.custom(
                color: AppColors.textPrimary,
                size: 20,
                weight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'When you deactivate your account:',
              style: AppTypography.custom(
                color: AppColors.textSecondary,
                size: 14,
                weight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            _InfoItem(
              text: 'Your profile will be hidden from other users',
            ),
            _InfoItem(
              text: 'Your content will remain but won\'t be visible',
            ),
            _InfoItem(
              text: 'You won\'t be able to log in',
            ),
            _InfoItem(
              text: 'You can reactivate by contacting support',
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showConfirmationDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error500,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text('Deactivate Account'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgSurface,
        title: Text(
          'Final Confirmation',
          style: AppTypography.custom(
            color: AppColors.textPrimary,
            size: 18,
            weight: FontWeight.w600,
          ),
        ),
        content: Text(
          'This action will deactivate your account. You will need to contact support to reactivate it.',
          style: AppTypography.custom(
            color: AppColors.textSecondary,
            size: 14,
            weight: FontWeight.w400,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deactivateAccount(context);
            },
            child: Text(
              'Deactivate',
              style: TextStyle(color: AppColors.error500),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deactivateAccount(BuildContext context) async {
    // TODO: Call API
    // await apiClient.post('/users/deactivate', {});
    // Navigate to login screen and clear session
    // Navigator.of(context).pushNamedAndRemoveUntil(
    //   AppRoutes.signIn,
    //   (route) => false,
    // );
  }
}

class _InfoItem extends StatelessWidget {
  final String text;

  const _InfoItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 20,
            color: AppColors.warning500,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTypography.custom(
                color: AppColors.textMuted,
                size: 13,
                weight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

#### Step 2: Add to Settings

In settings screen, add:

```dart
_ProfileTile(
  icon: Icons.block,
  title: 'Deactivate Account',
  subtitle: 'Temporarily disable your account',
  iconColor: AppColors.error500,
  titleColor: AppColors.error500,
  onTap: () => Navigator.of(context).pushNamed(AppRoutes.deactivateAccount),
)
```

---

## Integration Checklist

### Backend
- [ ] Update Prisma schema for all three features
- [ ] Run migrations
- [ ] Create/update services and controllers
- [ ] Add proper authentication and authorization
- [ ] Update filters in feed services
- [ ] Add notification support for mentions
- [ ] Test all endpoints

### Frontend
- [ ] Create mention input widget
- [ ] Create mention display widget
- [ ] Add block/unblock functionality
- [ ] Create blocked users screen
- [ ] Create account deactivation screen
- [ ] Add API client methods
- [ ] Update routes
- [ ] Test user flows

### Database Indexes
Ensure these indexes exist for performance:
- `mentions.mentionedUserId`
- `mentions.creatorId`
- `mentions.commentId`
- `mentions.postId`
- `user_blocks.blockerId`
- `user_blocks.blockedId`
- `users.isActive`

---

**Last Updated**: February 2026
