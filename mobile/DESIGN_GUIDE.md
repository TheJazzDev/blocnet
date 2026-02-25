# Blocnet Mobile App - Design Pattern Guide

This guide documents the design patterns and conventions used in the Blocnet mobile app. Use this guide to ensure consistency when adding new features or screens.

## Table of Contents
1. [Color System](#color-system)
2. [Typography](#typography)
3. [Screen Structure](#screen-structure)
4. [Common Components](#common-components)
5. [Spacing & Layout](#spacing--layout)
6. [Button Styles](#button-styles)
7. [Card & Container Patterns](#card--container-patterns)
8. [State Indicators](#state-indicators)

---

## Color System

### Importing Colors
```dart
import 'package:blocnet/app/theme.dart';
```

### Primary Colors
| Use Case | Color | Code |
|----------|-------|------|
| Background (Base) | Dark Gray | `AppColors.bgBase` |
| Background (Surface) | Slightly Lighter | `AppColors.bgSurface` |
| Background (Elevated) | Cards/Modals | `AppColors.bgElevated` |
| Primary Actions | Blue/Cyan | `AppColors.primary400`, `AppColors.primary500` |
| Borders (Subtle) | Faint Gray | `AppColors.borderSubtle` |

### Text Colors
| Use Case | Color | Code |
|----------|-------|------|
| Primary Text | White | `AppColors.textPrimary` |
| Secondary Text | Light Gray | `AppColors.textSecondary` |
| Muted Text | Medium Gray | `AppColors.textMuted` |
| Faint Text | Dark Gray | `AppColors.textFaint` |

### Semantic Colors
| Use Case | Color | Code |
|----------|-------|------|
| Success | Green | `AppColors.successColor` |
| Warning | Amber/Orange | `AppColors.warning500` |
| Error | Red | `AppColors.error500` |

### Space-Specific Accents
```dart
// User space accent (blue)
AppColors.userAccent  // #2563EB

// Hunter space accent (cyan)
AppColors.hunterAccent  // #0deef2
```

---

## Typography

### Importing Typography
```dart
import 'package:blocnet/app/typography.dart';
```

### Usage Pattern
**Always use `AppTypography.custom()` instead of raw `TextStyle`:**

```dart
// ✅ CORRECT
Text(
  'Title Text',
  style: AppTypography.custom(
    color: AppColors.textPrimary,
    size: 18,
    weight: FontWeight.w600,
  ),
)

// ❌ INCORRECT
Text(
  'Title Text',
  style: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  ),
)
```

### Common Text Styles
```dart
// Section Headers (16-18px, bold)
AppTypography.custom(
  color: AppColors.textPrimary,
  size: 16,
  weight: FontWeight.w700,
)

// Body Text (14px, regular)
AppTypography.custom(
  color: AppColors.textMuted,
  size: 14,
  weight: FontWeight.w400,
)

// Small/Caption Text (12px)
AppTypography.custom(
  color: AppColors.textFaint,
  size: 12,
  weight: FontWeight.w500,
)

// Large Titles (22-24px)
AppTypography.custom(
  color: AppColors.textPrimary,
  size: 22,
  weight: FontWeight.w800,
)
```

---

## Screen Structure

### Standard Screen Template

```dart
import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:flutter/material.dart';

class MyScreen extends StatelessWidget {
  const MyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: const CustomAppBar(
        title: 'Screen Title',
        backButton: true,
        showSearch: false,
        showFilter: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Screen content here
          ],
        ),
      ),
    );
  }
}
```

### CustomAppBar Properties
```dart
CustomAppBar(
  title: 'Title',         // Screen title
  backButton: true,       // Show back button
  showSearch: false,      // Show search icon
  showFilter: false,      // Show filter icon
)
```

### Screen with TabBar
For screens that need tabs (like Badges, Quests):

```dart
appBar: PreferredSize(
  preferredSize: const Size.fromHeight(kToolbarHeight + 48),
  child: Column(
    children: [
      CustomAppBar(
        title: 'Screen Title',
        backButton: true,
        showSearch: false,
        showFilter: false,
      ),
      Container(
        color: AppColors.bgBase,
        child: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary400,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary400,
          tabs: const [
            Tab(text: 'Tab 1'),
            Tab(text: 'Tab 2'),
          ],
        ),
      ),
    ],
  ),
),
```

---

## Common Components

### Card/Container Pattern

**Always use Container instead of Card widget:**

```dart
// ✅ CORRECT
Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: AppColors.bgSurface,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(
      color: AppColors.borderSubtle,
      width: 1,
    ),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Card content
    ],
  ),
)

// ❌ INCORRECT
Card(
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        // Card content
      ],
    ),
  ),
)
```

### Section Labels
```dart
Text(
  'Section Title',
  style: AppTypography.custom(
    color: AppColors.textPrimary,
    size: 16,
    weight: FontWeight.w700,
  ),
)
```

### List Tiles/Items
```dart
Container(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  decoration: BoxDecoration(
    color: AppColors.bgSurface,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: AppColors.borderSubtle,
      width: 1,
    ),
  ),
  child: Row(
    children: [
      Icon(Icons.icon_name, color: AppColors.primary400, size: 20),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Title',
              style: AppTypography.custom(
                color: AppColors.textSecondary,
                size: 14,
                weight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Description',
              style: AppTypography.custom(
                color: AppColors.textMuted,
                size: 12,
                weight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    ],
  ),
)
```

---

## Spacing & Layout

### Standard Spacing Values
```dart
const SizedBox(height: 8)   // Small gap between related items
const SizedBox(height: 12)  // Medium gap within sections
const SizedBox(height: 16)  // Standard gap between components
const SizedBox(height: 24)  // Large gap between sections
const SizedBox(height: 32)  // Extra large gap for major sections
```

### Padding Conventions
```dart
// Screen padding
padding: const EdgeInsets.all(16)

// Card/Container padding
padding: const EdgeInsets.all(16)
padding: const EdgeInsets.all(20)  // For emphasis

// Button padding
padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)
```

---

## Button Styles

### Primary Button (Elevated)
```dart
ElevatedButton(
  onPressed: () {},
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary500,
    foregroundColor: Colors.black,  // or Colors.white depending on design
    padding: const EdgeInsets.symmetric(vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
  ),
  child: Text('Button Text'),
)
```

### Button with Icon
```dart
ElevatedButton.icon(
  onPressed: () {},
  icon: Icon(Icons.icon_name, size: 18),
  label: Text('Button Text'),
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary500,
    foregroundColor: Colors.black,
    padding: const EdgeInsets.symmetric(vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
  ),
)
```

### Loading State in Button
```dart
ElevatedButton.icon(
  onPressed: isLoading ? null : () {},
  icon: isLoading
      ? const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
      : Icon(Icons.icon_name, size: 18),
  label: Text(isLoading ? 'Loading...' : 'Action'),
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary500,
    foregroundColor: Colors.black,
  ),
)
```

---

## Card & Container Patterns

### Basic Content Card
```dart
Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: AppColors.bgSurface,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(
      color: AppColors.borderSubtle,
      width: 1,
    ),
  ),
  child: // content
)
```

### Gradient Card (for emphasis)
```dart
Container(
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppColors.primary500.withValues(alpha: 0.15),
        AppColors.teal500.withValues(alpha: 0.1),
      ],
    ),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: AppColors.primary500.withValues(alpha: 0.3),
      width: 1.5,
    ),
  ),
  child: // content
)
```

### Status/State Card
```dart
// Success State
Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: AppColors.successColor.withValues(alpha: 0.1),
    borderRadius: BorderRadius.circular(14),
    border: Border.all(
      color: AppColors.successColor.withValues(alpha: 0.3),
      width: 1,
    ),
  ),
  child: // content
)

// Warning State
Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: AppColors.warning500.withValues(alpha: 0.1),
    borderRadius: BorderRadius.circular(14),
    border: Border.all(
      color: AppColors.warning500.withValues(alpha: 0.3),
      width: 1,
    ),
  ),
  child: // content
)

// Error State
Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: AppColors.error500.withValues(alpha: 0.1),
    borderRadius: BorderRadius.circular(14),
    border: Border.all(
      color: AppColors.error500.withValues(alpha: 0.3),
      width: 1,
    ),
  ),
  child: // content
)
```

---

## State Indicators

### Status Chips
```dart
Container(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  decoration: BoxDecoration(
    color: statusColor.withValues(alpha: 0.15),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: statusColor.withValues(alpha: 0.5),
      width: 1.5,
    ),
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(statusIcon, size: 16, color: statusColor),
      const SizedBox(width: 6),
      Text(
        statusText,
        style: AppTypography.custom(
          color: statusColor,
          size: 13,
          weight: FontWeight.bold,
        ),
      ),
    ],
  ),
)
```

### Badge/Tag Chips
```dart
Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  decoration: BoxDecoration(
    color: AppColors.bgBase,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: AppColors.borderSubtle,
      width: 1,
    ),
  ),
  child: Text(
    'Tag Label',
    style: AppTypography.custom(
      color: AppColors.textMuted,
      size: 12,
      weight: FontWeight.w500,
    ),
  ),
)
```

### SnackBar Messages
```dart
// Success
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Success message'),
    backgroundColor: AppColors.successColor,
    behavior: SnackBarBehavior.floating,
  ),
)

// Error
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Error message'),
    backgroundColor: AppColors.error500,
    behavior: SnackBarBehavior.floating,
  ),
)
```

---

## Quick Reference Checklist

When creating a new screen or component:

- [ ] Import `AppColors` and `AppTypography`
- [ ] Import `CustomAppBar` if it's a full screen
- [ ] Set `backgroundColor: AppColors.bgBase` on Scaffold
- [ ] Use `CustomAppBar` instead of regular `AppBar`
- [ ] Use `Container` with `AppColors.bgSurface` instead of `Card`
- [ ] Use `AppTypography.custom()` for all text styles
- [ ] Use `AppColors.textPrimary/textSecondary/textMuted/textFaint` for text colors
- [ ] Use `AppColors.borderSubtle` for borders
- [ ] Use `borderRadius: BorderRadius.circular(14)` for cards
- [ ] Use `borderRadius: BorderRadius.circular(10-12)` for buttons
- [ ] Apply proper spacing (8, 12, 16, 24, 32)
- [ ] Style buttons with `AppColors.primary500` background
- [ ] Use semantic colors for states (success, warning, error)

---

## Examples

For complete examples, see:
- **Screen with tabs**: `/lib/features/quests/presentation/pages/quests_page.dart`
- **Detail screen**: `/lib/features/quests/presentation/pages/quest_detail_page.dart`
- **Simple screen**: `/lib/screen/referral_code_screen.dart`
- **Settings screen**: `/lib/screen/settings_screen.dart`
- **Profile screens**: `/lib/screen/profile/user_profile_body.dart`

---

## Color Replacement Guide

When updating legacy code:

| Old (Don't Use) | New (Use This) |
|----------------|----------------|
| `Colors.grey.shade300` | `AppColors.textSecondary` |
| `Colors.grey.shade400` | `AppColors.textFaint` or `AppColors.textMuted` |
| `Colors.grey.shade600` | `AppColors.borderSubtle` |
| `Colors.grey.shade800` | `AppColors.bgBase` |
| `Colors.grey.shade900` | `AppColors.bgSurface` |
| `Colors.amber.shade400` | `AppColors.warning500` |
| `Colors.blue.shade300/400` | `AppColors.primary400` or `AppColors.primary500` |
| `Colors.green.shade400` | `AppColors.successColor` |
| `Colors.red` | `AppColors.error500` |
| `Card` widget | `Container` with `AppColors.bgSurface` |
| `TextStyle(...)` | `AppTypography.custom(...)` |

---

**Last Updated**: February 2026
**Maintained by**: Development Team
