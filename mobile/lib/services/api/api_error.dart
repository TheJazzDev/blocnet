import 'dart:convert';

import 'package:blocnet/services/api/api_client.dart';

String describeApiError(
  Object error, {
  String fallback = 'Something went wrong. Please try again.',
}) {
  if (error is ApiException) {
    final body = error.responseBody?.trim();
    if (body != null && body.isNotEmpty) {
      try {
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) {
          final message = decoded['message']?.toString().trim();
          if (message != null && message.isNotEmpty) {
            return message;
          }
          final detail = decoded['error']?.toString().trim();
          if (detail != null && detail.isNotEmpty) {
            return detail;
          }
        }
      } catch (_) {
        // Ignore parse failure and continue to fallback values.
      }
    }

    final message = error.message.trim();
    if (message.isNotEmpty && message.toLowerCase() != 'request failed') {
      return message;
    }

    if (error.statusCode != null) {
      return 'Request failed (${error.statusCode})';
    }

    return fallback;
  }

  final message = error.toString().trim();
  if (message.isEmpty) {
    return fallback;
  }
  if (message.startsWith('Exception:')) {
    return message.substring('Exception:'.length).trim();
  }
  return message;
}
