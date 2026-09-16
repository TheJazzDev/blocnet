import 'dart:convert';

import 'package:blocnet/services/api/api_client.dart';

/// Turns a failed mining request into a sentence a member can act on.
///
/// The backend answers business conflicts as `{ code, message }`. The `code`
/// is checked first: the server `message` is written for developers
/// ("Claim the previous mining cycle before starting a new one") and used to
/// shadow the friendly copy below, which was therefore unreachable (F-54).
class MiningErrorCopy {
  const MiningErrorCopy._();

  static const String claimRequired =
      'Claim your completed cycle before starting a new one.';
  static const String notClaimable =
      'Nothing to claim yet — this cycle pays out once it finishes.';
  static const String claimWindowExpired =
      'That cycle expired before it was claimed, so its points were '
      'forfeited. Start a new cycle to keep mining.';
  static const String miningPaused =
      'Mining is paused right now. You can still claim a finished cycle.';

  static String describe(Object error) {
    if (error is! ApiException) return error.toString();

    final body = _parseBody(error.responseBody);
    final code = body?['code']?.toString();
    final fromCode = _copyForCode(code);
    if (fromCode != null) return fromCode;

    final message = _readMessage(body?['message']);
    if (message != null && message.toLowerCase() == 'mining is disabled') {
      return miningPaused;
    }
    if (message != null) return message;

    return error.message;
  }

  static String? _copyForCode(String? code) {
    switch (code) {
      case 'claim_required':
        return claimRequired;
      case 'not_claimable':
        return notClaimable;
      case 'claim_window_expired':
        return claimWindowExpired;
      case 'mining_disabled':
        return miningPaused;
    }
    return null;
  }

  static Map<String, dynamic>? _parseBody(String? raw) {
    final body = raw?.trim();
    if (body == null || body.isEmpty) return null;
    try {
      final parsed = jsonDecode(body);
      if (parsed is Map<String, dynamic>) return parsed;
    } catch (_) {
      // Not JSON: fall back to the transport message.
    }
    return null;
  }

  static String? _readMessage(Object? raw) {
    if (raw is List) {
      final joined = raw.map((part) => part.toString()).join(' ').trim();
      return joined.isEmpty ? null : joined;
    }
    final message = raw?.toString().trim();
    return (message == null || message.isEmpty) ? null : message;
  }
}
