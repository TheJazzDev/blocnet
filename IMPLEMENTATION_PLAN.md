# BlocNet MVP Implementation Plan

## Project Overview
BlocNet is a notification-driven crypto project update platform where users can follow blockchain projects and receive real-time notifications about important updates and actions.

## Current State Analysis

### Implemented (Partial)
- ✅ Basic home feed with posts
- ✅ Project and post data models
- ✅ Post cards and project cards UI
- ✅ Trending, Priority, Discover screens (basic)
- ✅ Auth screen placeholders
- ✅ Firebase/Firestore setup
- ✅ Provider state management setup

### Missing for MVP
- ❌ Real Firebase Authentication (Google + Email Magic Link)
- ❌ User profile with followed projects, saved posts, activity
- ❌ Complete settings screen
- ❌ Real-time notifications with FCM
- ❌ User interactions (follow, save, like, comment)
- ❌ Admin features (create project, create post)
- ❌ Search functionality
- ❌ Clean file structure

---

## New File Structure

```
lib/
├── main.dart
├── firebase_options.dart
│
├── core/                                   # App-wide configuration
│   ├── config/
│   │   └── app_config.dart                # App constants
│   ├── theme/
│   │   ├── app_theme.dart                 # Theme configuration
│   │   ├── app_colors.dart                # Color scheme
│   │   └── app_text_styles.dart           # Typography
│   ├── routes/
│   │   ├── app_router.dart                # Route management
│   │   └── route_names.dart               # Route constants
│   └── utils/
│       ├── date_formatter.dart
│       ├── validators.dart
│       └── helpers.dart
│
├── features/                               # Feature modules
│   │
│   ├── auth/                              # Authentication feature
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── user_model.dart
│   │   │   ├── repositories/
│   │   │   │   └── auth_repository.dart
│   │   │   └── services/
│   │   │       └── auth_service.dart      # Firebase Auth logic
│   │   └── presentation/
│   │       ├── pages/
│   │       │   ├── splash_page.dart       # Auth check
│   │       │   ├── sign_in_page.dart      # Email + Google sign in
│   │       │   ├── sign_up_page.dart      # Email + Google sign up
│   │       │   └── email_link_page.dart   # Magic link handler
│   │       ├── widgets/
│   │       │   ├── auth_button.dart
│   │       │   └── auth_text_field.dart
│   │       └── providers/
│   │           └── auth_provider.dart
│   │
│   ├── projects/                          # Projects & Posts feature
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   ├── project_model.dart     # Updated with followers
│   │   │   │   ├── post_model.dart        # Updated with likes/comments
│   │   │   │   ├── comment_model.dart     # NEW
│   │   │   │   ├── admin_model.dart
│   │   │   │   ├── primary_tag_model.dart
│   │   │   │   ├── secondary_tag_model.dart
│   │   │   │   └── priority_model.dart
│   │   │   ├── repositories/
│   │   │   │   ├── project_repository.dart
│   │   │   │   └── post_repository.dart
│   │   │   └── services/
│   │   │       └── firestore_service.dart
│   │   └── presentation/
│   │       ├── pages/
│   │       │   ├── home_page.dart         # Main feed
│   │       │   ├── explore_page.dart      # Explore section
│   │       │   ├── trending_page.dart     # Trending projects
│   │       │   ├── discover_page.dart     # Discover new projects
│   │       │   ├── priority_page.dart     # Priority filtered view
│   │       │   ├── project_detail_page.dart  # Full project details
│   │       │   ├── post_detail_page.dart  # Post with comments
│   │       │   └── search_page.dart       # NEW - Search projects/posts
│   │       ├── widgets/
│   │       │   ├── cards/
│   │       │   │   ├── project_card.dart
│   │       │   │   ├── post_card.dart
│   │       │   │   └── comment_card.dart  # NEW
│   │       │   ├── dialogs/
│   │       │   │   ├── project_details_dialog.dart
│   │       │   │   └── post_details_dialog.dart
│   │       │   ├── filters/
│   │       │   │   ├── filter_bottom_sheet.dart
│   │       │   │   ├── tag_selector.dart
│   │       │   │   └── priority_selector.dart
│   │       │   └── shared/
│   │       │       ├── app_bar.dart
│   │       │       ├── toggle_button.dart
│   │       │       └── labels.dart
│   │       └── providers/
│   │           ├── projects_provider.dart
│   │           ├── posts_provider.dart
│   │           └── comments_provider.dart # NEW
│   │
│   ├── profile/                           # User Profile feature
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   ├── user_profile_model.dart
│   │   │   │   └── activity_model.dart    # User activity tracking
│   │   │   └── repositories/
│   │   │       └── profile_repository.dart
│   │   └── presentation/
│   │       ├── pages/
│   │       │   ├── profile_page.dart      # Main profile with tabs
│   │       │   └── edit_profile_page.dart # Edit name, avatar, bio
│   │       ├── widgets/
│   │       │   ├── profile_header.dart    # Avatar, name, stats
│   │       │   ├── followed_projects_tab.dart
│   │       │   ├── saved_posts_tab.dart
│   │       │   └── activity_tab.dart      # User activity history
│   │       └── providers/
│   │           └── profile_provider.dart
│   │
│   ├── settings/                          # Settings feature
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── settings_model.dart
│   │   │   └── repositories/
│   │   │       └── settings_repository.dart
│   │   └── presentation/
│   │       ├── pages/
│   │       │   ├── settings_page.dart     # Main settings menu
│   │       │   ├── theme_settings_page.dart      # Dark/Light mode
│   │       │   ├── notification_settings_page.dart  # Notification prefs
│   │       │   ├── account_settings_page.dart    # Account management
│   │       │   ├── about_page.dart        # About BlocNet
│   │       │   ├── help_page.dart         # Help & Support
│   │       │   └── privacy_page.dart      # Privacy Policy
│   │       └── providers/
│   │           └── settings_provider.dart
│   │
│   ├── notifications/                     # Notifications feature
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── notification_model.dart
│   │   │   ├── repositories/
│   │   │   │   └── notification_repository.dart
│   │   │   └── services/
│   │   │       └── fcm_service.dart       # Firebase Cloud Messaging
│   │   └── presentation/
│   │       ├── pages/
│   │       │   └── notifications_page.dart
│   │       ├── widgets/
│   │       │   └── notification_card.dart
│   │       └── providers/
│   │           └── notifications_provider.dart
│   │
│   └── admin/                             # Admin feature
│       ├── data/
│       │   ├── repositories/
│       │   │   ├── admin_project_repository.dart
│       │   │   └── admin_post_repository.dart
│       │   └── services/
│       │       └── admin_service.dart     # Admin permissions check
│       └── presentation/
│           ├── pages/
│           │   ├── admin_dashboard_page.dart
│           │   ├── create_project_page.dart   # Create new project
│           │   ├── edit_project_page.dart     # Edit existing project
│           │   ├── create_post_page.dart      # Create project update
│           │   ├── edit_post_page.dart        # Edit post
│           │   └── manage_projects_page.dart  # List admin's projects
│           ├── widgets/
│           │   ├── project_form.dart
│           │   ├── post_form.dart
│           │   └── rich_text_editor.dart  # For post content
│           └── providers/
│               └── admin_provider.dart
│
└── shared/                                # Shared UI components
    ├── widgets/
    │   ├── buttons/
    │   │   ├── primary_button.dart
    │   │   ├── secondary_button.dart
    │   │   └── icon_button.dart
    │   ├── inputs/
    │   │   ├── text_field.dart
    │   │   └── search_bar.dart
    │   ├── cards/
    │   │   ├── stat_card.dart
    │   │   └── tag_card.dart
    │   ├── dialogs/
    │   │   ├── confirmation_dialog.dart
    │   │   └── loading_dialog.dart
    │   ├── loading/
    │   │   ├── loading_indicator.dart
    │   │   └── skeleton_loader.dart
    │   └── navigation/
    │       └── bottom_nav_bar.dart
    └── extensions/
        ├── context_extensions.dart
        ├── string_extensions.dart
        └── date_extensions.dart
```

---

## Data Models Updates

### 1. User Model (NEW)
```dart
class AppUser {
  String id;
  String email;
  String? displayName;
  String? photoURL;
  String? bio;
  List<String> followedProjectIds;
  List<String> savedPostIds;
  DateTime createdAt;
  DateTime lastActive;
  bool isAdmin;
  List<String> adminProjectIds; // Projects user is admin of
}
```

### 2. Project Model (UPDATE)
```dart
class Project {
  // Existing fields...
  List<String> followerIds;       // NEW - User IDs following this project
  int followersCount;             // Keep synced with followerIds.length
  int postsCount;                 // Total posts
  int totalLikes;                 // Aggregate likes across all posts
}
```

### 3. Post Model (UPDATE)
```dart
class Post {
  // Existing fields...
  List<String> likedByUserIds;    // NEW - User IDs who liked
  int likesCount;                 // Keep synced
  int commentsCount;              // Total comments
  int viewsCount;                 // Track views
}
```

### 4. Comment Model (NEW)
```dart
class Comment {
  String id;
  String postId;
  String userId;
  String userDisplayName;
  String? userPhotoURL;
  String content;
  DateTime createdAt;
  DateTime? editedAt;
  List<String> likedByUserIds;    // Comments can be liked too
  int likesCount;
}
```

### 5. Notification Model (NEW)
```dart
enum NotificationType {
  newPost,           // New post from followed project
  postUpdate,        // Update to existing post
  commentReply,      // Reply to user's comment
  projectUpdate,     // Project details updated
  urgentPost,        // High priority post
}

class AppNotification {
  String id;
  String userId;
  NotificationType type;
  String title;
  String body;
  String? imageUrl;
  Map<String, dynamic> data;  // Additional data (projectId, postId, etc.)
  bool isRead;
  DateTime createdAt;
}
```

### 6. Activity Model (NEW)
```dart
enum ActivityType {
  followedProject,
  unfollowedProject,
  savedPost,
  unsavedPost,
  likedPost,
  commentedOnPost,
  createdProject,
  createdPost,
}

class UserActivity {
  String id;
  String userId;
  ActivityType type;
  String description;
  Map<String, dynamic> metadata;  // projectId, postId, etc.
  DateTime timestamp;
}
```

---

## Implementation Phases

### Phase 1: Structure Reorganization (Day 1)
- [x] Create new directory structure
- [ ] Move existing files to new locations
- [ ] Update all imports across the codebase
- [ ] Remove local dummy data files
- [ ] Test that app still runs

### Phase 2: Core Infrastructure (Day 1-2)
- [ ] Update data models with new fields
- [ ] Set up Firebase Authentication
  - Google Sign-In
  - Email Magic Link
  - Auth state management
- [ ] Create base repositories and services
- [ ] Set up theme provider (dark/light mode)
- [ ] Create shared widgets library

### Phase 3: Authentication Flow (Day 2)
- [ ] Splash screen with auth check
- [ ] Sign in page (Email + Google)
- [ ] Sign up page (Email + Google)
- [ ] Email verification flow
- [ ] Auth guards for protected routes

### Phase 4: User Interactions (Day 3)
- [ ] Follow/unfollow projects
- [ ] Save/unsave posts
- [ ] Like/unlike posts
- [ ] Comment on posts
- [ ] Reply to comments
- [ ] Update Firestore with user actions

### Phase 5: Profile Feature (Day 3-4)
- [ ] Profile page with tabs
- [ ] Edit profile (name, avatar, bio)
- [ ] Followed projects tab
- [ ] Saved posts tab
- [ ] Activity history tab
- [ ] Profile repository and provider

### Phase 6: Settings Feature (Day 4)
- [ ] Main settings page
- [ ] Theme settings (dark/light toggle)
- [ ] Notification preferences
- [ ] Account settings (change email, password, delete account)
- [ ] About page
- [ ] Help & Support page
- [ ] Privacy Policy page

### Phase 7: Notifications (Day 5)
- [ ] Set up Firebase Cloud Messaging
- [ ] FCM service for handling notifications
- [ ] Notifications page with list
- [ ] Notification cards
- [ ] Mark as read functionality
- [ ] Background notification handling
- [ ] In-app notification display
- [ ] Notification triggers on Firestore changes

### Phase 8: Admin Features (Day 5-6)
- [ ] Admin dashboard
- [ ] Create project form
- [ ] Edit project form
- [ ] Create post form (rich text editor)
- [ ] Edit post form
- [ ] Manage projects page
- [ ] Admin permissions check
- [ ] Image upload for projects/posts

### Phase 9: Search & Discovery (Day 6)
- [ ] Search page
- [ ] Search projects by name/tags
- [ ] Search posts by content
- [ ] Recent searches
- [ ] Search filters

### Phase 10: Polish & Testing (Day 7)
- [ ] UI/UX refinements
- [ ] Loading states and error handling
- [ ] Form validation
- [ ] Navigation flow testing
- [ ] Firestore security rules
- [ ] Performance optimization
- [ ] Bug fixes

---

## Firestore Collections Structure

```
users/
  {userId}/
    - id
    - email
    - displayName
    - photoURL
    - bio
    - followedProjectIds[]
    - savedPostIds[]
    - createdAt
    - lastActive
    - isAdmin
    - adminProjectIds[]

projects/
  {projectId}/
    - [existing fields]
    - followerIds[]
    - followersCount
    - postsCount
    - totalLikes

posts/
  {postId}/
    - [existing fields]
    - likedByUserIds[]
    - likesCount
    - commentsCount
    - viewsCount

comments/
  {commentId}/
    - id
    - postId
    - userId
    - userDisplayName
    - userPhotoURL
    - content
    - createdAt
    - editedAt
    - likedByUserIds[]
    - likesCount

notifications/
  {notificationId}/
    - id
    - userId
    - type
    - title
    - body
    - imageUrl
    - data{}
    - isRead
    - createdAt

activities/
  {activityId}/
    - id
    - userId
    - type
    - description
    - metadata{}
    - timestamp
```

---

## Required Dependencies

Add to `pubspec.yaml`:
```yaml
dependencies:
  # Authentication
  firebase_auth: ^5.0.0
  google_sign_in: ^6.2.1

  # Cloud Messaging
  firebase_messaging: ^15.0.0
  flutter_local_notifications: ^18.0.0

  # Image handling
  image_picker: ^1.1.2
  cached_network_image: ^3.4.1
  firebase_storage: ^12.0.0

  # Rich text editor
  flutter_quill: ^10.8.0

  # State management (already have provider)
  # provider: ^6.1.5 ✓

  # Utils
  timeago: ^3.7.0
  share_plus: ^10.0.0
```

---

## Next Steps

1. **Review this plan** - Confirm the structure and approach
2. **Prioritize features** - If timeline is tight, which features are most critical?
3. **Start reorganization** - I'll begin moving files to new structure
4. **Implement phase by phase** - Build systematically

**Questions:**
1. Do you approve of this file structure?
2. Should I proceed with full reorganization now?
3. Any changes to the implementation phases?
4. Timeline expectations? (This is 5-7 days of focused work)

Let me know and I'll start the reorganization!
