# 🔄 Font Migration Guide

## Problem
There are **44 files** with hardcoded `GoogleFonts.spaceGrotesk()` and `GoogleFonts.inter()` calls that bypass the centralized typography system.

## Solution: Global Find & Replace

### Step 1: Remove GoogleFonts Import

**Find in ALL files:**
```dart
import 'package:google_fonts/google_fonts.dart';
```

**Replace with:**
```dart
import 'package:blocnet/app/typography.dart';
```

### Step 2: Replace GoogleFonts Calls

Since GoogleFonts calls have various parameters, we need to replace them with `AppTypography.custom()`:

#### Pattern 1: GoogleFonts.spaceGrotesk (Headings)

**Before:**
```dart
GoogleFonts.spaceGrotesk(
  color: AppColors.textPrimary,
  fontSize: 17,
  fontWeight: FontWeight.w700,
)
```

**After:**
```dart
AppTypography.custom(
  size: 17,
  weight: FontWeight.w700,
  color: AppColors.textPrimary,
)
```

#### Pattern 2: GoogleFonts.inter (Body Text)

**Before:**
```dart
GoogleFonts.inter(
  color: AppColors.textMuted,
  fontSize: 12,
  fontWeight: FontWeight.w400,
)
```

**After:**
```dart
AppTypography.custom(
  size: 12,
  weight: FontWeight.w400,
  color: AppColors.textMuted,
)
```

### Affected Files (44 total):

Core screens with most occurrences:
- `lib/features/mining/presentation/widgets/mining_hero_card.dart` (8 occurrences)
- `lib/screen/main_screen.dart` (6+ occurrences)
- `lib/screen/wallet_screen.dart`
- `lib/screen/profile_screen.dart`
- `lib/features/hunter/presentation/pages/hunter_hub_screen.dart`
- And 39 more files...

## Recommended Approach

### Option A: Use VS Code Find & Replace (Recommended for You)

1. Open VS Code
2. Press `Cmd+Shift+F` (Mac) or `Ctrl+Shift+F` (Windows/Linux)
3. Enable **Regex mode** (button: `.*`)
4. **Find**: `GoogleFonts\.(spaceGrotesk|inter)\(`
5. Click "Replace All" button multiple times to review each replacement

Then manually update parameters:
- `fontSize:` → `size:`
- `fontWeight:` → `weight:`
- Keep `color:` as is

### Option B: Let Claude Do It (Will take multiple iterations)

I can go through each file and replace them, but it will require ~44 file edits.

### Option C: Bash Script (Fastest but risky)

I can write a script to automatically replace all occurrences, but you should review changes after.

## After Migration

Run:
```bash
flutter analyze
```

Should show: **"No issues found!"**

## Benefits After Migration

✅ Change font **once** in `typography.dart` → entire app updates
✅ No more `GoogleFonts.spaceGrotesk` vs `GoogleFonts.inter` mixing
✅ Consistent typography across all screens
✅ User accessibility fonts respected everywhere

## Which approach do you prefer?

1. **Manual** (You do find & replace in VS Code)
2. **Automated** (I update all 44 files for you)
3. **Hybrid** (I create a bash script you run)
