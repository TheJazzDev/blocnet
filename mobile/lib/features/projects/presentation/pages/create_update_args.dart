import 'package:flutter/foundation.dart';

/// Route arguments for the composer (`AppRoutes.createUpdate`).
///
/// [projectId] pre-selects a gem. [updateId] opens the composer in edit
/// mode, which submits a `PATCH /updates/:id`.
@immutable
class CreateUpdateArgs {
  const CreateUpdateArgs({this.projectId, this.updateId});

  final String? projectId;
  final String? updateId;

  bool get isEdit => updateId != null && updateId!.isNotEmpty;

  /// Accepts the args object or a plain map (deep links, notifications).
  static CreateUpdateArgs from(Object? raw) {
    if (raw is CreateUpdateArgs) return raw;
    if (raw is Map) {
      String? read(String key) {
        final value = raw[key]?.toString().trim() ?? '';
        return value.isEmpty ? null : value;
      }

      return CreateUpdateArgs(
        projectId: read('projectId'),
        updateId: read('updateId'),
      );
    }
    return const CreateUpdateArgs();
  }
}
