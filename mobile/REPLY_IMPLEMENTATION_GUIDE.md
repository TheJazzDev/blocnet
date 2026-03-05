# Reply Functionality - Complete Implementation Guide

## ✅ What's Already Done

### Backend (100% Complete)
- ✅ Database schema updated with `replyToId` fields
- ✅ Migration applied successfully
- ✅ DTOs accept optional `replyToId` parameter
- ✅ Services pass `replyToId` to database
- ✅ API responses include `replyTo.author` information

### Mobile Data Layer (100% Complete)
- ✅ `CommentModel` includes `replyToId` and `replyToAuthor` fields
- ✅ `CommunityPostComment` includes `replyToId` and `replyToAuthor` fields
- ✅ Models parse reply data from API

### Mobile UI (50% Complete)
- ✅ `CommunityDiscussionCommentCard` - Shows "Replying to @username" indicator + Reply button
- ✅ `CommunityDiscussionComposer` - Shows reply context banner with cancel button
- ⏳ Need to wire up in `CommunityPostDiscussionScreen`
- ⏳ Need to update repository to send `replyToId`
- ⏳ Need to implement same for update comments

---

## 🔧 Step-by-Step Implementation

### Step 1: Update Community Comments Repository

**File:** `mobile/lib/features/community/data/repositories/community_posts_repository.dart`

Find the `createComment` method and add `replyToId` parameter:

```dart
Future<CommunityPostComment?> createComment({
  required String postId,
  required String content,
  String? replyToId,  // ADD THIS
}) async {
  try {
    final response = await _apiClient.post(
      '/community-posts/$postId/comments',
      body: {
        'content': content,
        if (replyToId != null) 'replyToId': replyToId,  // ADD THIS
      },
    );
    // ... rest of method
  } catch (e) {
    // ... error handling
  }
}
```

### Step 2: Update Community Posts Store

**File:** `mobile/lib/services/community/community_posts_store.dart`

Update the `createComment` method (around line 231):

```dart
Future<CommunityPostComment?> createComment({
  required String postId,
  required String content,
  String? replyToId,  // ADD THIS
}) async {
  final created = await _repository.createComment(
    postId: postId,
    content: content,
    replyToId: replyToId,  // ADD THIS
  );

  // ... rest of method stays the same
}
```

### Step 3: Wire Up Reply in Community Discussion Screen

**File:** `mobile/lib/features/community/presentation/pages/community_post_discussion_screen.dart`

**3a. Add state variables** (after line 39):

```dart
String? _replyToCommentId;
String? _replyToUsername;
```

**3b. Add reply handler method** (before `_sendComment`):

```dart
void _handleReply(String commentId, String? username) {
  setState(() {
    _replyToCommentId = commentId;
    _replyToUsername = username;
  });
  _commentFocusNode.requestFocus();
}

void _cancelReply() {
  setState(() {
    _replyToCommentId = null;
    _replyToUsername = null;
  });
}
```

**3c. Update `_sendComment` method** (around line 191):

```dart
Future<void> _sendComment(String postId) async {
  final text = _commentCtrl.text.trim();
  if (text.isEmpty || _isSending) return;
  if (text.length > 300) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Community comments cannot exceed 300 characters'),
      ),
    );
    return;
  }

  setState(() => _isSending = true);
  try {
    final store = _communityPostsStore ?? context.read<CommunityPostsStore>();
    final created = await store.createComment(
      postId: postId,
      content: text,
      replyToId: _replyToCommentId,  // ADD THIS
    );

    if (created != null) {
      _commentCtrl.clear();
      _cancelReply();  // ADD THIS - Clear reply state after sending
    }
  } catch (_) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to send comment')),
    );
  } finally {
    if (mounted) setState(() => _isSending = false);
  }
}
```

**3d. Update comment card rendering** (find where `CommunityDiscussionCommentCard` is used):

```dart
CommunityDiscussionCommentCard(
  comment: comment,
  onReply: () => _handleReply(
    comment.id,
    comment.admin?.username ?? comment.admin?.name,
  ),  // ADD THIS
),
```

**3e. Update composer widget** (find where `CommunityDiscussionComposer` is used, around line 339):

```dart
CommunityDiscussionComposer(
  controller: _commentCtrl,
  focusNode: _commentFocusNode,
  mentionsRepository: _mentionsRepository,
  isSending: _isSending,
  onSendTap: () => _sendComment(postId),
  replyingToUsername: _replyToUsername,  // ADD THIS
  onCancelReply: _cancelReply,  // ADD THIS
),
```

---

### Step 4: Update Comments (for Updates)

**File:** `mobile/lib/features/projects/presentation/widgets/update/update_details/update_details_dialog.dart`

This file is large, so here are the key changes needed:

**4a. Find the `_CommentTile` widget** and add `onReply` callback:

```dart
class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.hasLevel,
    this.onReply,  // ADD THIS
  });

  final Comment comment;
  final bool hasLevel;
  final VoidCallback? onReply;  // ADD THIS

  @override
  Widget build(BuildContext context) {
    // ... existing code ...

    // After the comment content (MentionText widget), add:
    if (comment.replyToAuthor != null) ...[
      Row(
        children: [
          Icon(
            Icons.subdirectory_arrow_right,
            size: 14,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: 4),
          Text(
            'Replying to @${_formatReplyUsername(comment.replyToAuthor!)}',
            style: AppTypography.custom(
              color: AppColors.textMuted,
              size: 12,
              weight: FontWeight.w500,
            ),
          ),
        ],
      ),
      const SizedBox(height: 6),
    ],

    // After content, before closing column:
    if (onReply != null) ...[
      const SizedBox(height: 8),
      GestureDetector(
        onTap: onReply,
        behavior: HitTestBehavior.opaque,
        child: Text(
          'Reply',
          style: AppTypography.custom(
            color: AppColors.textMuted,
            size: 12,
            weight: FontWeight.w600,
          ),
        ),
      ),
    ],
  }

  // Add helper method:
  String _formatReplyUsername(ReplyToAuthor author) {
    final username = author.username?.trim() ?? '';
    if (username.isNotEmpty) {
      return username.startsWith('@') ? username.substring(1) : username;
    }
    final displayName = author.displayName?.trim() ?? '';
    if (displayName.isNotEmpty) {
      return displayName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    }
    return author.id.substring(0, 6);
  }
}
```

**4b. Update `_CommentsSection`** state class:

```dart
class _CommentsSectionState extends State<_CommentsSection> {
  final TextEditingController _ctrl = MentionHighlightTextController();
  final FocusNode _focusNode = FocusNode();
  bool _isSending = false;
  String? _replyToCommentId;  // ADD THIS
  String? _replyToUsername;  // ADD THIS

  // Add reply handlers:
  void _handleReply(String commentId, String? username) {
    setState(() {
      _replyToCommentId = commentId;
      _replyToUsername = username;
    });
    _focusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyToCommentId = null;
      _replyToUsername = null;
    });
  }

  // Update _sendComment to include replyToId:
  Future<void> _sendComment() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    try {
      final store = context.read<CommentsStore>();
      await store.createComment(
        widget.updateId,
        text,
        replyToId: _replyToCommentId,  // ADD THIS
      );
      _ctrl.clear();
      _cancelReply();  // ADD THIS
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send comment')),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // In build method, update comment tile:
  _CommentTile(
    comment: comment,
    hasLevel: widget.hasLevel,
    onReply: () => _handleReply(  // ADD THIS
      comment.id,
      comment.admin?.username ?? comment.admin?.name,
    ),
  ),
}
```

**4c. Update composer UI** in `_CommentsSection` build method:

Add reply indicator banner above the text field (similar to community composer):

```dart
if (_replyToUsername != null) ...[
  Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(
      color: AppColors.bgElevated,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        Icon(
          Icons.subdirectory_arrow_right,
          size: 14,
          color: AppColors.textMuted,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Replying to @$_replyToUsername',
            style: AppTypography.custom(
              color: AppColors.textMuted,
              size: 12,
              weight: FontWeight.w500,
            ),
          ),
        ),
        GestureDetector(
          onTap: _cancelReply,
          child: Icon(
            Icons.close,
            size: 18,
            color: AppColors.textMuted,
          ),
        ),
      ],
    ),
  ),
],
```

### Step 5: Update Comments Store

**File:** `mobile/lib/services/community/comments_store.dart`

Update `createComment` method:

```dart
Future<void> createComment(
  String updateId,
  String content, {
  String? replyToId,  // ADD THIS
}) async {
  try {
    final response = await _apiClient.post(
      '/comments',
      body: {
        'updateId': updateId,
        'content': content,
        if (replyToId != null) 'replyToId': replyToId,  // ADD THIS
      },
    );
    // ... rest stays same
  } catch (e) {
    // ... error handling
  }
}
```

---

### Step 6: Remove Bookmark Icon from Update Modal

**File:** `mobile/lib/features/projects/presentation/widgets/update/update_details/update_details_dialog.dart`

**Find the section with bookmark button** (likely in a row with other action buttons) and:

1. **Remove the bookmark icon/button** entirely
2. **Move the Send button** to where the bookmark was (or keep it in the same position)

Look for code similar to:
```dart
Row(
  children: [
    // Bookmark button - REMOVE THIS
    IconButton(
      icon: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border),
      onPressed: () => _toggleBookmark(),
    ),

    // Other buttons...

    // Send button - KEEP THIS, adjust position as needed
    IconButton(
      icon: Icon(Icons.send),
      onPressed: () => _sendComment(),
    ),
  ],
)
```

Change to:
```dart
Row(
  children: [
    // Remove bookmark button

    // Other buttons...

    // Send button stays
    IconButton(
      icon: Icon(Icons.send),
      onPressed: () => _sendComment(),
    ),
  ],
)
```

---

## 📋 Testing Checklist

After implementation, test:

- [ ] Community: Click Reply button → Composer shows "Replying to @username"
- [ ] Community: Send reply → Comment shows "Replying to @username" indicator
- [ ] Community: Cancel reply → Reply banner disappears
- [ ] Updates: Click Reply button → Composer shows reply context
- [ ] Updates: Send reply → Comment shows reply indicator
- [ ] Updates: Bookmark icon removed from modal
- [ ] Updates: Send button still works correctly
- [ ] Both: Multiple nested replies work
- [ ] Both: Reply to different users works
- [ ] Both: Mentions still work in replies

---

## 🎨 Design Notes

**Reply Indicator Style:**
- Icon: `Icons.subdirectory_arrow_right` (14px, muted color)
- Text: "Replying to @username" (12px, muted color)
- Username: Primary color, semi-bold (600 weight)
- Spacing: 6-8px above comment content

**Reply Button:**
- Text: "Reply" (12px, semi-bold, muted color)
- Position: Below comment content
- Spacing: 8px top margin
- Clickable: `GestureDetector` with `HitTestBehavior.opaque`

**Reply Context Banner:**
- Background: `AppColors.bgElevated`
- Padding: 12px horizontal, 8px vertical
- Border radius: 8px
- Contains: Arrow icon + text + close button
- Margin: 8px bottom (above text field)

---

## 🔗 Related Files

**Backend:**
- `backend/prisma/schema.prisma` - Database schema
- `backend/src/comments/dto/create-comment.dto.ts` - DTO
- `backend/src/comments/comments.service.ts` - Service
- `backend/src/community-posts/dto/create-community-post-comment.dto.ts` - DTO
- `backend/src/community-posts/community-posts.service.ts` - Service

**Mobile Data:**
- `mobile/lib/features/comments/data/models/comment_model.dart` - Model
- `mobile/lib/features/community/data/models/community_post_comment_model.dart` - Model

**Mobile UI (Updated):**
- `mobile/lib/features/community/presentation/widgets/community_discussion_comment_card.dart` ✅
- `mobile/lib/features/community/presentation/widgets/community_discussion_composer.dart` ✅

**Mobile UI (Needs Update):**
- `mobile/lib/features/community/presentation/pages/community_post_discussion_screen.dart`
- `mobile/lib/features/community/data/repositories/community_posts_repository.dart`
- `mobile/lib/services/community/community_posts_store.dart`
- `mobile/lib/features/projects/presentation/widgets/update/update_details/update_details_dialog.dart`
- `mobile/lib/services/community/comments_store.dart`
