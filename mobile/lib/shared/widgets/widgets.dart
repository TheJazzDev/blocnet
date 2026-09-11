/// Blocnet shared widgets. One import for the component library.
///
/// ```dart
/// import 'package:blocnet/shared/widgets/widgets.dart';
/// ```
///
/// Values live in `app/tokens/`; colour lives in `app/theme.dart`.
library;

export 'app_avatar.dart';
export 'app_button.dart';
export 'app_empty_state.dart';
export 'app_list_row.dart';
export 'app_pill.dart';
export 'app_section_header.dart';
export 'app_sheet.dart';
export 'app_stat_tile.dart';
export 'app_surface.dart';
export 'app_text_field.dart';
export 'user_name_with_level_icon.dart';

// Superseded by AppButton, kept while their 9 call sites migrate.
export 'app_primary_button.dart';
export 'app_secondary_button.dart';
export 'app_skeleton.dart';
