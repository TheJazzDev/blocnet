# Blocnet Mention System Documentation

This directory contains comprehensive documentation about the @mention implementation in the Blocnet Flutter mobile app and NestJS backend.

## Documentation Files

### 1. **MENTIONS_IMPLEMENTATION.md** (In `mobile/`)
Complete technical reference for the mention system.

**What it covers:**
- Detailed component breakdown (MentionTextField, MentionText, MentionHighlightTextController)
- Where mentions are currently integrated (3 locations)
- Backend implementation (MentionsService, MentionsController)
- Comment models and data structures
- Store layer (state management)
- Feature summary table
- API response formats
- All file paths and code patterns

**Best for:** Deep understanding, implementation details, code review

**Sections:**
- Part 1: Mention System Architecture
- Part 2: Where Mentions Are Integrated
- Part 3: Backend Implementation
- Part 4: Comment Models & Data Structures
- Part 5: UI Components for Displaying Comments
- Part 6: Store Layer (State Management)
- Part 7: Features Summary Table
- Part 8: Integration Points for Enhancement
- Part 9: API Response Format
- Key Files Reference

---

### 2. **MENTIONS_QUICK_REFERENCE.md** (In `mobile/`)
Quick cheat sheet for developers working with mentions.

**What it covers:**
- Where mentions currently work (visual tree)
- Core components and how to use them
- File locations for copy-paste
- Backend integration checklist
- Common code patterns
- Debugging tips
- API contract summary

**Best for:** Quick lookup, copy-paste code, troubleshooting

**Sections:**
- Where Mentions Work (Currently Implemented)
- Core Components (What to Use)
- File Locations (Copy-Paste Ready)
- Backend Integration Checklist
- Common Pattern
- Text Fields That STILL NEED Mentions
- Mention Features at a Glance
- API Contract
- Debugging
- Keyboard & UX Tips

---

### 3. **MENTION_ARCHITECTURE_VISUAL.txt** (In `blocnet/`)
ASCII diagram showing the complete system architecture.

**What it covers:**
- Frontend component layers (input and display)
- Integration points (where mentions work)
- API layer (REST endpoints)
- Backend module structure
- Complete data flow walkthrough
- Data models with exact fields
- Regex patterns

**Best for:** Understanding system flow, presentations, onboarding

**Sections:**
- Frontend Input Layers
- Frontend Display Layers
- Integration Points
- API Layer
- Backend Mentions Module
- Complete Data Flow Example
- Key Regex Pattern
- All Data Models

---

## Quick Start by Use Case

### I want to...

**Add mentions to a new text field**
1. Read: MENTIONS_QUICK_REFERENCE.md → "Text Fields That STILL NEED Mentions"
2. Check: MENTIONS_IMPLEMENTATION.md → "Part 8: Integration Points for Enhancement"
3. Copy pattern from: Community Create Post or Update Comments implementation

**Understand how mentions work end-to-end**
1. Read: MENTION_ARCHITECTURE_VISUAL.txt → "Data Flow" section
2. Then: MENTIONS_IMPLEMENTATION.md → "Part 1: Mention System Architecture"

**Find where to use MentionTextField**
1. Look: MENTIONS_QUICK_REFERENCE.md → "Core Components (What to Use)"
2. Examples: MENTIONS_IMPLEMENTATION.md → "Part 2: Where Mentions Are Integrated"

**Debug why mentions aren't showing**
1. Check: MENTIONS_QUICK_REFERENCE.md → "Debugging" section
2. Verify: Backend integration checklist steps

**See all file paths**
1. Check: MENTIONS_IMPLEMENTATION.md → "Key Files Reference" at end
2. Or: MENTIONS_QUICK_REFERENCE.md → "File Locations (Copy-Paste Ready)"

**Understand API contract**
1. Read: MENTIONS_QUICK_REFERENCE.md → "API Contract"
2. More detail: MENTIONS_IMPLEMENTATION.md → "Part 3: Backend Implementation"

---

## Where Mentions Currently Work

```
✅ IMPLEMENTED:
  • Community Post Creation (with autocomplete suggestions)
  • Community Post Comments (in discussion thread)
  • Update Comments (in update details dialog)
  
❌ NOT YET IMPLEMENTED:
  • Create Update Screen (content field)
  • Submit Project Screen (description field)
  • Profile Edit (bio field)
```

---

## Key Components Overview

| Component | Purpose | File |
|-----------|---------|------|
| **MentionTextField** | Text input with @mention autocomplete | `mobile/lib/features/mentions/presentation/widgets/mention_text_field.dart` |
| **MentionHighlightTextController** | Styles mentions in real-time (blue + bold) | Same file |
| **MentionText** | Displays and renders mentions (styled, clickable) | `mobile/lib/features/mentions/presentation/widgets/mention_text.dart` |
| **MentionsRepository** | API communication for search | `mobile/lib/features/mentions/data/repositories/mentions_repository.dart` |
| **MentionProfileNavigator** | Opens profiles when mention is tapped | `mobile/lib/features/mentions/presentation/utils/mention_profile_navigator.dart` |
| **MentionsService** (Backend) | Extracts mentions, creates records, sends notifications | `backend/src/mentions/mentions.service.ts` |
| **MentionsController** (Backend) | REST endpoint for autocomplete search | `backend/src/mentions/mentions.controller.ts` |

---

## Mention System at a Glance

**How it works:**
1. User types `@` in any MentionTextField
2. Autocomplete dropdown appears with user suggestions
3. User taps suggestion → `@username` is inserted and styled blue
4. User submits comment
5. Backend extracts mentions, creates mention records, sends notifications
6. Comment displayed with styled (blue, bold) clickable mentions
7. User taps mention → Opens profile in bottom sheet

**Regex Pattern:** `@([a-zA-Z0-9._-]+)`

**Supported Usernames:**
- `john.doe` ✓
- `jane-smith` ✓
- `user_name` ✓
- `user123` ✓

---

## Backend Mention Processing Flow

```
1. User submits comment: POST /updates/{updateId}/comments
   ├─ Body: { "content": "Hey @john check this!" }

2. CommentsService creates comment
   ├─ Calls: MentionsService.createCommentMentions()

3. MentionsService processes mentions
   ├─ Extracts: ["john"] using regex
   ├─ Looks up: User with username "john"
   ├─ Creates: Mention record in database
   └─ Sends: Notification to mentioned user

4. Mentioned user receives notification
   ├─ Type: mention_received
   ├─ Title: "You were mentioned"
   ├─ Body: "{Author} mentioned you in a comment"
   └─ DeepLink: Opens the comment
```

---

## File Organization

```
/blocnet/
├── MENTION_ARCHITECTURE_VISUAL.txt ← You are here
├── README_MENTIONS.md ← You are here
│
├── mobile/
│   ├── MENTIONS_IMPLEMENTATION.md
│   ├── MENTIONS_QUICK_REFERENCE.md
│   │
│   └── lib/features/mentions/
│       ├── data/
│       │   ├── models/
│       │   │   └── mention_user_model.dart
│       │   └── repositories/
│       │       └── mentions_repository.dart
│       └── presentation/
│           ├── utils/
│           │   └── mention_profile_navigator.dart
│           └── widgets/
│               ├── mention_text_field.dart (has MentionTextField + MentionHighlightTextController)
│               └── mention_text.dart
│
└── backend/src/
    └── mentions/
        ├── mentions.controller.ts
        ├── mentions.service.ts
        ├── mentions.module.ts
        └── dto/
            └── search-users.query.ts
```

---

## Quick API Reference

### Frontend
```dart
// Input with autocomplete
MentionTextField(
  controller: controller,
  mentionsRepository: MentionsRepository(ApiClient()),
)

// Display with styled mentions
MentionText(
  text: 'Hey @john check this!',
  onMentionTap: (username) => MentionProfileNavigator.openFromUsername(context, username),
)
```

### Backend
```typescript
// Search endpoint
GET /mentions/search?q=john&limit=5
// Returns: [{ id, username, displayName, avatarUrl }]

// Mention processing (automatic when comment is saved)
await MentionsService.createCommentMentions(commentId, content, userId)
```

---

## Common Tasks

### Add mentions to an existing text field

**Before:**
```dart
final controller = TextEditingController();
TextField(controller: controller)
```

**After:**
```dart
final controller = MentionHighlightTextController();
final mentionsRepo = MentionsRepository(ApiClient());

MentionTextField(
  controller: controller,
  mentionsRepository: mentionsRepo,
  hintText: 'Write...',
  minLines: 1,
  maxLines: 4,
)
```

### Display comment with mentions

**Before:**
```dart
Text(comment.content)
```

**After:**
```dart
MentionText(
  text: comment.content,
  onMentionTap: (username) {
    MentionProfileNavigator.openFromUsername(context, username);
  },
)
```

### Submit comment with mentions

**Code:**
```dart
// No changes needed! Just send raw content
final content = controller.text.trim();
await api.post('/updates/{updateId}/comments', {
  'content': content  // Contains "@mentions" as plain text
});
// Backend automatically:
// 1. Extracts mentions
// 2. Creates mention records
// 3. Sends notifications
```

---

## Debugging Checklist

- [ ] MentionTextField receives MentionsRepository instance?
- [ ] Backend `/mentions/search` endpoint returns users?
- [ ] MentionHighlightTextController used (not plain TextEditingController)?
- [ ] Backend calls MentionsService.create*Mentions() method?
- [ ] Mentioned user is not the author (backend filters this)?
- [ ] No duplicate notifications (deduplication working)?
- [ ] Mentions appear styled (blue + bold) in comment display?
- [ ] Mentions are clickable and open profiles?

---

## Important Notes

1. **Regex:** Mentions use pattern `@([a-zA-Z0-9._-]+)` everywhere
2. **Search:** Supports username, email, and display name matching
3. **Validation:** Mentions extracted on backend, not frontend
4. **Notifications:** Automatic with deduplication key
5. **Display:** Always use MentionText widget for rendering mentions
6. **Profile Cache:** MentionProfileNavigator caches profiles in memory
7. **Deduplication:** Prevents sending same mention notification twice

---

## Testing Mention Functionality

### Manual Testing Checklist
- [ ] Type `@` in comment field
- [ ] Autocomplete dropdown appears
- [ ] Type user name → suggestions filter
- [ ] Click suggestion → mention inserted at cursor
- [ ] Text appears blue and bold while typing
- [ ] Submit comment → appears in list
- [ ] Comment displays with blue mentions
- [ ] Tap mention → profile opens
- [ ] Mentioned user receives notification
- [ ] Multiple mentions in one comment work

### Edge Cases
- Mention at start of text
- Multiple mentions in one text
- Mention at end of text
- Mention with space before it
- Mentioning non-existent user
- Mentioning yourself (should be filtered)

---

## Related Documentation

- See MENTIONS_IMPLEMENTATION.md for complete technical details
- See MENTIONS_QUICK_REFERENCE.md for quick lookup and copy-paste code
- See MENTION_ARCHITECTURE_VISUAL.txt for system flow diagrams

---

## Questions?

Refer to the appropriate guide:
- **"How do I use MentionTextField?"** → MENTIONS_QUICK_REFERENCE.md
- **"What's the complete flow?"** → MENTION_ARCHITECTURE_VISUAL.txt
- **"Where's the code for X?"** → MENTIONS_IMPLEMENTATION.md
- **"How do I add mentions to a new field?"** → MENTIONS_IMPLEMENTATION.md, Part 8

