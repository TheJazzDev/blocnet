# 🎨 Font System Documentation

## Overview
The Blocnet mobile app uses a **centralized font system** that respects user preferences while maintaining a consistent design.

## How It Works

### Priority Order:
1. **User's Device Custom Font** (if accessibility font is set)
2. **App Fallback Font**: **Inter** (default)

## 🎯 Changing Fonts - ONE PLACE

To change the font for the **entire app**, edit this single file:

**File**: `lib/app/typography.dart`

**Location**: Line 42

```dart
return GoogleFonts.inter(  // ← CHANGE THIS LINE
  textStyle: textStyle,
  fontSize: size,
  fontWeight: weight,
  color: color,
  height: height,
  letterSpacing: letterSpacing,
);
```

### Font Options:

```dart
// Current (Inter)
GoogleFonts.inter(...)

// Other popular options:
GoogleFonts.spaceGrotesk(...)  // Geometric, modern
GoogleFonts.manrope(...)       // Clean, professional
GoogleFonts.dmSans(...)        // Friendly, readable
GoogleFonts.poppins(...)       // Rounded, approachable
GoogleFonts.roboto(...)        // Material Design standard
GoogleFonts.openSans(...)      // Web-safe, neutral
```

## 📝 Usage in Code

### Using Theme Styles (Recommended)
```dart
Text(
  'Hello World',
  style: Theme.of(context).textTheme.headlineMedium,
)
```

### Using AppTypography Directly
```dart
Text(
  'Hello World',
  style: AppTypography.headlineMedium(AppColors.textPrimary),
)
```

### Custom Sizes
```dart
Text(
  'Custom Text',
  style: AppTypography.custom(
    size: 18,
    weight: FontWeight.w600,
    color: AppColors.textPrimary,
  ),
)
```

## Available Styles

### Display (Large, Prominent)
- `displayLarge` - 56px, w800
- `displayMedium` - 40px, w800
- `displaySmall` - 32px, w700

### Headline (Section Headers)
- `headlineLarge` - 24px, w700
- `headlineMedium` - 20px, w700
- `headlineSmall` - 17px, w700

### Title (Card Titles, List Items)
- `titleLarge` - 16px, w600
- `titleMedium` - 14px, w600
- `titleSmall` - 12px, w600

### Body (Paragraphs, Content)
- `bodyLarge` - 15px, w400, line-height: 1.6
- `bodyMedium` - 13px, w400, line-height: 1.5
- `bodySmall` - 12px, w400, line-height: 1.5

### Label (Buttons, Tags, Badges)
- `labelLarge` - 12px, w500
- `labelMedium` - 11px, w500
- `labelSmall` - 10px, w600

## Files Modified

1. **`lib/app/typography.dart`** - Centralized font configuration (NEW)
2. **`lib/app/theme.dart`** - Updated to use AppTypography
3. **`lib/shared/styles/app_text_styles.dart`** - Removed hardcoded fonts

## Benefits

✅ **One Place to Change**: Update font globally in one line
✅ **Accessibility**: Respects user's custom accessibility fonts
✅ **Consistency**: Same font family across entire app
✅ **Easy Testing**: Switch fonts instantly for A/B testing
✅ **Type Safety**: No more hardcoded font strings
✅ **Maintainable**: Clear, documented system

## Testing Different Fonts

```bash
# 1. Edit lib/app/typography.dart (line 42)
# 2. Change GoogleFonts.inter to GoogleFonts.yourFont
# 3. Hot reload or restart app
flutter run
```

## Migration Notes

All previous font references (`GoogleFonts.spaceGrotesk`, `GoogleFonts.inter`, `fontFamily: 'Geist'`) have been replaced with the centralized `AppTypography` system.

No action needed - the app will automatically use the system font with Inter fallback!
