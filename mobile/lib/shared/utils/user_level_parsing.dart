import 'package:blocnet/features/levels/data/models/user_level_model.dart';

/// Parses an optional `currentLevel` object from an API payload.
///
/// Returns `null` when the field is absent, not a map, or malformed so models
/// tolerate backends that have not yet started sending the level.
UserLevelModel? parseCurrentLevel(Object? raw) {
  if (raw is! Map) return null;
  try {
    return UserLevelModel.fromApi(
      raw.map((key, value) => MapEntry(key.toString(), value)),
    );
  } catch (_) {
    return null;
  }
}
