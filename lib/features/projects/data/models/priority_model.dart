import 'package:blocnet/app/theme.dart';
import 'package:flutter/material.dart';

class Priority {
  final String label;
  final Color color;

  const Priority._(this.label, this.color);

  // Define the different urgency levels
  static final high = Priority._('High', AppColors.error500);
  static final low = Priority._('Low', AppColors.successColor);
  static final mid = Priority._('Mid', AppColors.warning500);

  /// Get all priority levels
  static List<Priority> getAll() {
    return [low, mid, high];
  }

  /// Get the priority level by its label
  static Priority fromJson(String json) {
    switch (json.toLowerCase()) {
      case 'low':
        return low;
      case 'mid':
        return mid;
      case 'high':
        return high;
      default:
        throw ArgumentError('Invalid priority level: $json');
    }
  }

  /// Serialize the priority to JSON
  String toJson() {
    return label;
  }

  /// Override toString to return the label
  @override
  String toString() {
    return label;
  }
}
