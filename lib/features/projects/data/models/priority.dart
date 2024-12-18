import 'package:blocknet/app/theme.dart';
import 'package:flutter/material.dart';

class Priority {
  final String label;
  final Color color;

  const Priority._(this.label, this.color);

  // Define the different urgency levels
  static final low = Priority._('Low', AppColors.successColor);
  static final medium = Priority._('Medium', AppColors.warning500);
  static final high = Priority._('High', AppColors.error500);

  static List<Priority> getAll() {
    return [low, medium, high];
  }

  // Get the urgency level by string
  static Priority fromString(String level) {
    switch (level.toLowerCase()) {
      case 'low':
        return low;
      case 'medium':
        return medium;
      case 'high':
        return high;
      default:
        throw ArgumentError('Invalid urgency level: $level');
    }
  }
}
