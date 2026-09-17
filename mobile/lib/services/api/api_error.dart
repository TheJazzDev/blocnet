import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:blocnet/services/api/api_client.dart';
import 'package:flutter/foundation.dart';

/// Shown when no response arrived at all.
const String networkErrorMessage =
    "Couldn't reach Blocnet. Check your connection and try again.";

/// Turns any error into text a member can read.
///
/// Only a 4xx carries a message written for people, so only a 4xx body is
/// shown. Server faults, bare status codes, transport errors and raw
/// exceptions become [fallback] or [networkErrorMessage]; the detail goes to
/// the debug log instead.
String describeApiError(
  Object error, {
  String fallback = 'Something went wrong. Please try again.',
}) {
  if (error is ApiException) {
    // The body of a 401 is raw backend auth text, never user copy.
    if (error.statusCode == 401) return ApiException.sessionUnconfirmedMessage;
    if (error.isNetworkError) return _logged(error, networkErrorMessage);
    final code = error.statusCode ?? 0;
    if (code >= 400 && code < 500) {
      final message = _bodyMessage(error.responseBody) ?? error.message.trim();
      // ApiClient words a 4xx without a body message itself.
      if (message.isNotEmpty && message != 'Request failed') return message;
    }
    return _logged(error, fallback);
  }
  if (error is SocketException ||
      error is TimeoutException ||
      error is HandshakeException) {
    return _logged(error, networkErrorMessage);
  }
  // `throw Exception('...')` is how the app words its own messages.
  final text = error.toString().trim();
  if (error is Exception && text.startsWith('Exception:')) {
    final message = text.substring('Exception:'.length).trim();
    if (message.isNotEmpty) return message;
  }
  return _logged(error, fallback);
}

String? _bodyMessage(String? body) {
  final trimmed = body?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  try {
    final decoded = jsonDecode(trimmed);
    if (decoded is! Map<String, dynamic>) return null;
    final raw = decoded['message'];
    // Validation errors arrive as a list of messages.
    final message = (raw is List ? raw.join('\n') : raw?.toString())?.trim();
    if (message != null && message.isNotEmpty) return message;
  } catch (_) {
    // Not JSON: nothing written for people.
  }
  return null;
}

String _logged(Object error, String copy) {
  debugPrint('[api] $error');
  return copy;
}
