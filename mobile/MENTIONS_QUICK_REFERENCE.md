# Mention System Quick Reference

## Where Mentions Work (Currently Implemented)

```
Community Posts
├── CREATE POST SCREEN ✅
│   └── Content field with @mention autocomplete
│       └── Creates mentions + notifications on save
│
└── DISCUSSION THREAD (Comments) ✅
    ├── Composer bar at bottom
    │   └── MentionTextField with autocomplete
    └── Comment cards display mentions
        └── Tappable mentions open profiles

Project Updates
└── UPDATE DETAILS DIALOG ✅
    ├── Comment input field
    │   └── MentionTextField in dialog
    └── Comment display
        └── MentionText widget for rendering
```

---

## Core Components (What to Use)

### For Text Input WITH Mentions
Use: **`MentionTextField`**

```dart
MentionTextField(
  controller: controller,
  focusNode: focusNode,
  mentionsRepository: MentionsRepository(ApiClient()),
  hintText: 'Write something...',
  minLines: 1,
  maxLines: 4,
  maxLength: 300,
)
```

Then use: **`MentionHighlightTextController`**

```dart
final controller = MentionHighlightTextController();
```

### For Text Display WITH Styled Mentions
Use: **`MentionText`**

```dart
MentionText(
  text: 'Hey @john.doe check this out!',
  onMentionTap: (username) {
    MentionProfileNavigator.openFromUsername(context, username);
  },
)
```

### For Opening Profile on Mention Click
Use: **`MentionProfileNavigator`**

```dart
MentionProfileNavigator.openFromUsername(context, 'john.doe');
```

---

## File Locations (Copy-Paste Ready)

| Need | Use This File |
|------|---------------|
| Input field with autocomplete | `/mobile/lib/features/mentions/presentation/widgets/mention_text_field.dart` |
| Display mentions with styling | `/mobile/lib/features/mentions/presentation/widgets/mention_text.dart` |
| Search mentions API | `/mobile/lib/features/mentions/data/repositories/mentions_repository.dart` |
| User model for mentions | `/mobile/lib/features/mentions/data/models/mention_user_model.dart` |
| Open profile from mention | `/mobile/lib/features/mentions/presentation/utils/mention_profile_navigator.dart` |
| Backend search endpoint | `/backend/src/mentions/mentions.controller.ts` |
| Backend mention processing | `/backend/src/mentions/mentions.service.ts` |

---

## Backend Integration Checklist

When mentions are submitted:

- [ ] Extract mentions with regex: `@([a-zA-Z0-9._-]+)`
- [ ] Call `MentionsService.createCommentMentions(commentId, content, userId)`
- [ ] OR `MentionsService.createCommunityPostMentions(postId, content, userId)`
- [ ] OR `MentionsService.createCommunityPostCommentMentions(commentId, content, userId)`
- [ ] Service creates mention records
- [ ] Service sends notifications automatically
- [ ] Deduplication handled (no duplicate notifications)

---

## Common Pattern

```dart
// 1. Create controller
final _controller = MentionHighlightTextController();
final _mentionsRepo = MentionsRepository(ApiClient());

// 2. Add to text field
MentionTextField(
  controller: _controller,
  mentionsRepository: _mentionsRepo,
)

// 3. On submit
final content = _controller.text.trim();
await api.post('/endpoint', { 'content': content });
// Backend extracts mentions automatically

// 4. Display when fetched
MentionText(
  text: comment.content,
  onMentionTap: (username) {
    MentionProfileNavigator.openFromUsername(context, username);
  }
)
```

---

## Text Fields That STILL NEED Mentions

- [ ] Create Update Screen - content field
- [ ] Submit Project Screen - description field
- [ ] Profile Edit - bio/description fields

To add mentions:
1. Change `TextEditingController()` → `MentionHighlightTextController()`
2. Change `TextField()` → `MentionTextField()`
3. Add `MentionsRepository` instance
4. Backend automatically processes mentions (if service is called)

---

## Mention Features at a Glance

| Feature | What Happens |
|---------|--------------|
| **Type @ symbol** | Autocomplete dropdown appears after `@` |
| **Type name** | Searches users (debounced 180ms) |
| **Click suggestion** | Inserts `@username ` at cursor |
| **Save with @mention** | Backend extracts username |
| **Mentioned user** | Receives notification with deeplink |
| **View mention** | Styled in blue + bold |
| **Click mention** | Opens user's profile in bottom sheet |

---

## API Contract

### Search Endpoint
```
GET /mentions/search?q=john&limit=5
```

Response:
```json
[
  {
    "id": "uuid",
    "username": "john.doe",
    "displayName": "John Doe",
    "avatarUrl": "url"
  }
]
```

### Submit Comment with Mentions
```
POST /updates/{updateId}/comments
Body: { "content": "Hey @john.doe check this!" }
```

Backend automatically:
- Extracts `["john.doe"]`
- Creates mention record
- Sends notification to john.doe

---

## Debugging

If mentions aren't working:

1. Check MentionTextField is receiving MentionsRepository ✓
2. Verify backend `/mentions/search` endpoint returns users ✓
3. Check that `MentionHighlightTextController` is used (not plain TextEditingController) ✓
4. On submit, verify backend calls `MentionsService.create*Mentions()` method ✓
5. Check user is not mentioned themselves (backend filters this) ✓

---

## Keyboard & UX Tips

- Overlay appears below field, positioned smart
- Closes when user types space after @
- Closes when suggestions list is empty
- Send button disabled while submitting
- Multiple mentions supported: `@john @jane @bob`
- Case-insensitive matching
- Supports usernames with dots/dashes: `john.doe`, `jane-smith`

