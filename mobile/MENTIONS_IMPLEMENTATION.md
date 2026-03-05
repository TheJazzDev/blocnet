# Mention Implementation Analysis - Blocnet Flutter Mobile App

## Executive Summary

The Blocnet mobile app has a comprehensive @mention system implemented across two main text input areas:
1. **Community Posts** - Creating posts and commenting on posts
2. **Update Comments** - Commenting on project updates

The mention system includes:
- Real-time autocomplete suggestions
- Visual highlighting of mentions
- Backend-driven user search
- Mention notifications
- Clickable mention display in text

---

## Part 1: Mention System Architecture

### 1.1 Core Mention Components (Frontend)

#### **MentionTextField** - Smart Text Input with Autocomplete
Location: `/Users/jazzdev/Documents/Programming/blocnet/mobile/lib/features/mentions/presentation/widgets/mention_text_field.dart`

**What it does:**
- Extends Flutter's `TextField` with @mention autocomplete functionality
- Shows dropdown suggestions when user types `@` followed by text
- Automatically inserts selected mention and focuses cursor after mention

**Key Features:**
- Debounced search (180ms delay) to avoid excessive API calls
- Overlay-based suggestion dropdown
- Smart mention detection stops when user types a space or newline
- Displays 5 user suggestions at a time
- Shows avatar, display name, and username for each suggestion

**Regex Pattern:** `@([a-zA-Z0-9._-]+)` - Matches valid usernames

**Props:**
```dart
class MentionTextField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? hintText;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final MentionsRepository mentionsRepository;
  final ValueChanged<String>? onChanged;
  final bool showFocusHighlight;
}
```

---

#### **MentionHighlightTextController** - Visual Styling
Location: Same file

**What it does:**
- Extends `TextEditingController` to provide real-time visual styling
- Colors @mentions in primary blue (`AppColors.primary400`)
- Makes mentions bold (`FontWeight.w600`)
- Handles text composition (ime input, autocorrect underlines)

**Style Applied:**
```dart
mentionStyle = baseStyle.copyWith(
  color: AppColors.primary400,      // Blue color
  fontWeight: FontWeight.w600,       // Bold weight
);
```

---

#### **MentionText** - Display Component for Rendered Text
Location: `/Users/jazzdev/Documents/Programming/blocnet/mobile/lib/features/mentions/presentation/widgets/mention_text.dart`

**What it does:**
- Renders plain text with styled mentions
- Provides clickable mentions (tappable gesture recognition)
- Used for displaying comments and posts after they're saved

**Features:**
- Detects mentions in already-rendered text
- Optional callback when mention is tapped: `onMentionTap(username)`
- Customizable styles for text and mentions
- Used in comment cards and post displays

---

### 1.2 Mention Search & Data Layer

#### **MentionsRepository** - API Communication
Location: `/Users/jazzdev/Documents/Programming/blocnet/mobile/lib/features/mentions/data/repositories/mentions_repository.dart`

**Endpoint:** `GET /mentions/search?q={query}&limit={limit}`

**Implementation:**
```dart
Future<List<MentionUserModel>> searchUsers(String query, {int limit = 10})
```

**Query Processing:**
1. Removes `@` symbol from query (normalizes input)
2. Sends to backend with optional limit (default 10)
3. Backend returns array of user objects
4. Filters to `MentionUserModel` instances

**Error Handling:**
- Returns empty list on API errors
- Logs errors to debug console
- Non-blocking (doesn't crash UI)

---

#### **MentionUserModel** - Data Model
Location: `/Users/jazzdev/Documents/Programming/blocnet/mobile/lib/features/mentions/data/models/mention_user_model.dart`

```dart
class MentionUserModel {
  final String id;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  
  // JSON serialization included
}
```

---

#### **MentionProfileNavigator** - Deep Link Handler
Location: `/Users/jazzdev/Documents/Programming/blocnet/mobile/lib/features/mentions/presentation/utils/mention_profile_navigator.dart`

**What it does:**
- Opens user profiles when mention is tapped
- Caches profile lookups for performance
- Handles deduplication of in-flight requests
- Normalizes usernames (removes @, lowercase)

**Flow:**
1. User taps mention in comment/post
2. Navigator looks up full user profile from backend
3. Shows `PublicProfileScreen` as modal sheet

**Caching:**
```dart
static final Map<String, Admin> _profileCache = <String, Admin>{};
static final Map<String, Future<Admin?>> _inFlightLookups = <String, Future<Admin?>>{};
```

---

## Part 2: Where Mentions Are Integrated

### 2.1 Community Posts - Creating Posts

**File:** `/Users/jazzdev/Documents/Programming/blocnet/mobile/lib/features/community/presentation/pages/community_create_post_screen.dart`

**Implementation Details:**

| Aspect | Details |
|--------|---------|
| **Controller** | `MentionHighlightTextController()` |
| **Input Widget** | `MentionTextField` |
| **Max Length** | 300 characters |
| **Min/Max Lines** | 8 min, 12 max |
| **Hint Text** | "What's on your mind?" |
| **API Endpoint** | `POST /community-posts` |
| **Store** | `CommunityPostsStore` |

**Code Pattern:**
```dart
final TextEditingController _contentCtrl = MentionHighlightTextController();
final MentionsRepository _mentionsRepository = MentionsRepository(ApiClient());

MentionTextField(
  controller: _contentCtrl,
  focusNode: _contentFocus,
  mentionsRepository: _mentionsRepository,
  hintText: "What's on your mind?",
  minLines: 8,
  maxLines: 12,
  showFocusHighlight: false,
)
```

**Backend Processing:**
- Mentions extracted on backend (see MentionsService.extractMentions)
- Notifications sent to mentioned users
- Mention records created in database

---

### 2.2 Community Post Comments - Discussion Thread

**File:** `/Users/jazzdev/Documents/Programming/blocnet/mobile/lib/features/community/presentation/pages/community_post_discussion_screen.dart`

**Implementation Details:**

| Aspect | Details |
|--------|---------|
| **Controller** | `MentionHighlightTextController()` |
| **Composer Widget** | `CommunityDiscussionComposer` |
| **Max Length** | 300 characters |
| **Min/Max Lines** | 1 min, 4 max |
| **Hint Text** | "Write a comment..." |
| **API Endpoint** | `POST /community-posts/{postId}/comments` |
| **Store** | `CommunityPostsStore` |
| **Realtime Updates** | Yes (watched via store listener) |

**Flow:**
```dart
final TextEditingController _commentCtrl = MentionHighlightTextController();

// Inside CommunityDiscussionComposer widget
CommunityDiscussionComposer(
  controller: controller,
  focusNode: focusNode,
  mentionsRepository: mentionsRepository,
  isSending: isSending,
  onSendTap: onSendTap,
)
```

**Composer Component:**
Location: `/Users/jazzdev/Documents/Programming/blocnet/mobile/lib/features/community/presentation/widgets/community_discussion_composer.dart`

- Row layout with MentionTextField and send button
- Real-time text validation
- Send button disabled while sending

---

### 2.3 Update Comments - Project Update Discussion

**File:** `/Users/jazzdev/Documents/Programming/blocnet/mobile/lib/features/projects/presentation/widgets/update/update_details/update_details_dialog.dart`

**Implementation Details:**

| Aspect | Details |
|--------|---------|
| **Controller** | `MentionHighlightTextController()` |
| **Input Widget** | `MentionTextField` |
| **Max Length** | Not explicitly capped (uses TextEditingController) |
| **Min/Max Lines** | Not set (default single-line behavior) |
| **Hint Text** | Not specified in widget |
| **API Endpoint** | `POST /updates/{updateId}/comments` |
| **Store** | `CommentsStore` |
| **Realtime Updates** | Yes (watched via watchCommentsRealtime) |

**Code Pattern:**
```dart
final TextEditingController _commentController = MentionHighlightTextController();
final MentionsRepository _mentionsRepository = MentionsRepository(ApiClient());

MentionTextField(
  controller: _commentController,
  focusNode: _commentFocusNode,
  mentionsRepository: _mentionsRepository,
)
```

**Features:**
- Optional focus on load via `focusCommentComposer` parameter
- Auto-scroll to comment section when focused
- Embedded in scrollable dialog

---

### 2.4 Text Input Fields WITHOUT Mentions

**Files that do NOT have mention support:**

1. **Submit Project Screen** - `submit_project_screen.dart`
   - Text fields: name, symbol, website, description, reason
   - Uses standard `TextEditingController`

2. **Create Update Screen** - `create_update_screen.dart`
   - Text fields: title, content
   - Uses standard `TextEditingController`
   - Could be enhanced with mentions for update content

3. **Sign In/Sign Up Pages**
   - Uses `AuthInputField` widget (custom)
   - No mention support

4. **Edit Profile**
   - Uses standard text inputs
   - No mention support

5. **Send Token Page**
   - Uses standard inputs
   - No mention support

---

## Part 3: Backend Implementation

### 3.1 Mentions Module

**Location:** `/Users/jazzdev/Documents/Programming/blocnet/backend/src/mentions/`

**Files:**
- `mentions.controller.ts` - API route
- `mentions.service.ts` - Business logic
- `mentions.module.ts` - Module configuration
- `dto/search-users.query.ts` - Input validation

---

#### **MentionsController** - API Endpoint

```typescript
@Get('search')
@UseGuards(AuthGuard)
async searchUsers(@Query() query: SearchUsersQuery) {
  return this.mentionsService.searchUsers(query.q, query.limit);
}
```

**Endpoint:** `GET /mentions/search?q={query}&limit={limit}`

**Returns:**
```typescript
{
  id: string;
  username: string;
  displayName?: string;
  avatarUrl?: string;
}[]
```

---

#### **MentionsService** - Core Logic

**Key Methods:**

| Method | Purpose |
|--------|---------|
| `extractMentions(content)` | Parses text, extracts @usernames |
| `searchUsers(query, limit)` | Fuzzy search users for autocomplete |
| `createCommentMentions(commentId, content, authorId)` | Process mentions in update comments |
| `createCommunityPostMentions(postId, content, authorId)` | Process mentions in community posts |
| `createCommunityPostCommentMentions(commentId, content, authorId)` | Process mentions in comment replies |

**Mention Extraction Regex:**
```typescript
const mentionRegex = /@([a-zA-Z0-9._-]+)/g;
```

**Mention Record Created:**
```prisma
{
  mentionedUserId: string;
  mentionText: string;
  commentId?: string;
  communityPostId?: string;
  communityPostCommentId?: string;
}
```

**Notification Sent:**
- Type: `mention_received`
- Title: "You were mentioned"
- Body: "{Author} mentioned you in a {context type}"
- Deep link: Opens relevant post/update/comment

---

### 3.2 Comments Integration

**Location:** `/Users/jazzdev/Documents/Programming/blocnet/backend/src/comments/`

**Service Integration:**
```typescript
// In CommentsService.createComment()
await this.mentionsService.createCommentMentions(
  comment.id,
  content,
  user.id
);
```

**Flow:**
1. User submits comment via mobile
2. Backend creates comment record
3. `MentionsService.createCommentMentions` called
4. Mentions extracted from content
5. Mentioned users looked up
6. Mention records created
7. Notifications sent with deduplication key

**Deduplication Key:**
```typescript
`mention_${contextType}_${Object.values(context)[0]}_${user.id}`
```
- Prevents duplicate notifications for same mention

---

### 3.3 Community Posts Integration

**Location:** `/Users/jazzdev/Documents/Programming/blocnet/backend/src/community-posts/`

Similar flow to comments:
1. Create community post
2. Call `createCommunityPostMentions`
3. Extract mentions
4. Send notifications

---

## Part 4: Comment Models & Data Structures

### 4.1 Update Comments Model

**File:** `/Users/jazzdev/Documents/Programming/blocnet/mobile/lib/features/comments/data/models/comment_model.dart`

```dart
class CommentModel {
  final String id;
  final String updateId;
  final String authorId;
  final String content;        // Raw text with @mentions
  final DateTime createdAt;
  final DateTime updatedAt;
  final Admin? admin;           // Author profile info
}
```

**Note:** Comments store raw content with mentions. Frontend renders using `MentionText` widget.

---

### 4.2 Community Post Comments Model

**File:** `/Users/jazzdev/Documents/Programming/blocnet/mobile/lib/features/community/data/models/community_post_comment_model.dart`

```dart
class CommunityPostComment {
  final String id;
  final String postId;
  final String authorId;
  final String content;         // Raw text with @mentions
  final DateTime createdAt;
  final DateTime updatedAt;
  final Admin? admin;            // Author profile info
}
```

---

## Part 5: UI Components for Displaying Comments

### 5.1 Community Discussion Comment Card

**File:** `/Users/jazzdev/Documents/Programming/blocnet/mobile/lib/features/community/presentation/widgets/community_discussion_comment_card.dart`

- Displays comment with author info
- Renders mentions using `MentionText` widget
- Clickable mentions navigate to profile

---

### 5.2 Community Post Details Card

**File:** `/Users/jazzdev/Documents/Programming/blocnet/mobile/lib/features/community/presentation/widgets/community_discussion_post_details_card.dart`

- Shows original post content
- Uses `MentionText` for mention rendering

---

### 5.3 Update Comments Section

**File:** `/Users/jazzdev/Documents/Programming/blocnet/mobile/lib/features/projects/presentation/widgets/update/update_details/update_details_dialog.dart`

- Embedded in update details dialog
- Shows comment list + input composer
- Comments render with `MentionText`

---

## Part 6: Store Layer (State Management)

### 6.1 Community Posts Store

**File:** `/Users/jazzdev/Documents/Programming/blocnet/mobile/lib/services/community/community_posts_store.dart`

**Methods Related to Comments:**
- `fetchComments(postId)` - Load comments for post
- `watchCommentsRealtime(postId)` - Listen for new comments
- `createComment(postId, content)` - Submit comment with mentions
- `commentsForPost(postId)` - Get cached comments

---

### 6.2 Comments Store

**File:** `/Users/jazzdev/Documents/Programming/blocnet/mobile/lib/services/community/comments_store.dart`

**Methods:**
- `fetchComments(updateId)` - Load update comments
- `watchCommentsRealtime(updateId)` - Realtime listener
- `createComment(updateId, content)` - Submit with mention processing

---

## Part 7: Features Summary Table

| Feature | Implemented | Location | Notes |
|---------|-------------|----------|-------|
| **Input with Autocomplete** | ✅ | `MentionTextField` | Debounced search, overlay dropdown |
| **Visual Highlighting** | ✅ | `MentionHighlightTextController` | Blue + bold styling |
| **Mention Search API** | ✅ | `GET /mentions/search` | Fuzzy search by username/email |
| **Mention Rendering** | ✅ | `MentionText` widget | Styled, clickable mentions |
| **Profile Navigation** | ✅ | `MentionProfileNavigator` | Opens profile when mention tapped |
| **Community Post Mentions** | ✅ | `community_create_post_screen.dart` | Full support with suggestions |
| **Community Comment Mentions** | ✅ | `community_post_discussion_screen.dart` | Embedded composer |
| **Update Comment Mentions** | ✅ | `update_details_dialog.dart` | Within update details |
| **Mention Notifications** | ✅ | `MentionsService` | Sends to mentioned users |
| **Deduplication** | ✅ | Backend | Prevents duplicate notifications |
| **Project/Gem Mention Support** | ❌ | Not implemented | Could enhance gem submission forms |
| **Update Content Mentions** | ❌ | Not implemented | Title/content fields don't use MentionTextField |

---

## Part 8: Integration Points for Enhancement

If you want to add mention support to other text fields:

### **Gem/Project Submission Form**
**File:** `submit_project_screen.dart`
- Change `_descriptionController` from `TextEditingController` to `MentionHighlightTextController`
- Wrap description field with `MentionTextField`
- Add `MentionsRepository` initialization
- Mentions would need to be processed on backend during project creation

### **Update Creation Form**
**File:** `create_update_screen.dart`
- Change `_contentController` to `MentionHighlightTextController`
- Wrap with `MentionTextField`
- Add `MentionsRepository` initialization
- Would need `MentionsService.createUpdateMentions()` method on backend

---

## Part 9: API Response Format

**Autocomplete Search Response:**
```json
[
  {
    "id": "user-id-123",
    "username": "john.doe",
    "displayName": "John Doe",
    "avatarUrl": "https://cdn.example.com/john.png"
  },
  {
    "id": "user-id-456",
    "username": "jane.smith",
    "displayName": "Jane Smith",
    "avatarUrl": "https://cdn.example.com/jane.png"
  }
]
```

**Create Comment with Mentions:**
```json
{
  "content": "Hey @john.doe and @jane.smith, great work on the update!"
}
```

Backend extracts: `["john.doe", "jane.smith"]` and processes accordingly.

---

## Key Files Reference

| Component | File Path |
|-----------|-----------|
| **MentionTextField** | `/Users/jazzdev/Documents/Programming/blocnet/mobile/lib/features/mentions/presentation/widgets/mention_text_field.dart` |
| **MentionText** | `/Users/jazzdev/Documents/Programming/blocnet/mobile/lib/features/mentions/presentation/widgets/mention_text.dart` |
| **MentionUserModel** | `/Users/jazzdev/Documents/Programming/blocnet/mobile/lib/features/mentions/data/models/mention_user_model.dart` |
| **MentionsRepository** | `/Users/jazzdev/Documents/Programming/blocnet/mobile/lib/features/mentions/data/repositories/mentions_repository.dart` |
| **MentionProfileNavigator** | `/Users/jazzdev/Documents/Programming/blocnet/mobile/lib/features/mentions/presentation/utils/mention_profile_navigator.dart` |
| **Community Create Post** | `/Users/jazzdev/Documents/Programming/blocnet/mobile/lib/features/community/presentation/pages/community_create_post_screen.dart` |
| **Community Discussion Screen** | `/Users/jazzdev/Documents/Programming/blocnet/mobile/lib/features/community/presentation/pages/community_post_discussion_screen.dart` |
| **Community Composer** | `/Users/jazzdev/Documents/Programming/blocnet/mobile/lib/features/community/presentation/widgets/community_discussion_composer.dart` |
| **Update Details Dialog** | `/Users/jazzdev/Documents/Programming/blocnet/mobile/lib/features/projects/presentation/widgets/update/update_details/update_details_dialog.dart` |
| **Backend MentionsController** | `/Users/jazzdev/Documents/Programming/blocnet/backend/src/mentions/mentions.controller.ts` |
| **Backend MentionsService** | `/Users/jazzdev/Documents/Programming/blocnet/backend/src/mentions/mentions.service.ts` |
| **Backend CommentsService** | `/Users/jazzdev/Documents/Programming/blocnet/backend/src/comments/comments.service.ts` |
| **CommentModel (Updates)** | `/Users/jazzdev/Documents/Programming/blocnet/mobile/lib/features/comments/data/models/comment_model.dart` |
| **CommunityPostComment** | `/Users/jazzdev/Documents/Programming/blocnet/mobile/lib/features/community/data/models/community_post_comment_model.dart` |

