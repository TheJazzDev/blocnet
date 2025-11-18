import 'package:flutter/material.dart';

class Helpers {
  /// Show a snackbar with a message
  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: duration,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show an error snackbar
  static void showError(BuildContext context, String message) {
    showSnackBar(context, message, isError: true);
  }

  /// Show a success snackbar
  static void showSuccess(BuildContext context, String message) {
    showSnackBar(context, message, isError: false);
  }

  /// Format large numbers (e.g., 1000 -> 1K, 1000000 -> 1M)
  static String formatNumber(int number) {
    if (number < 1000) {
      return number.toString();
    } else if (number < 1000000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    }
  }

  /// Get initials from a name
  static String getInitials(String name) {
    if (name.isEmpty) return '';

    final nameParts = name.trim().split(' ');
    if (nameParts.length == 1) {
      return nameParts[0][0].toUpperCase();
    }

    return (nameParts[0][0] + nameParts[nameParts.length - 1][0]).toUpperCase();
  }

  /// Check if a string is a valid image URL
  static bool isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;

    final imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'svg'];
    final lowerUrl = url.toLowerCase();

    return imageExtensions.any((ext) => lowerUrl.endsWith('.$ext')) ||
        lowerUrl.contains('image');
  }

  /// Truncate text with ellipsis
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}
