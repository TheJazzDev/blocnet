import 'package:blocnet/app/theme.dart';
import 'package:flutter/material.dart';

class Priority {
  final String label;
  final Color color;

  const Priority._(this.label, this.color);

  // Define the different urgency levels
  static final high = Priority._('High', AppColors.priorityHigh);
  static final mid = Priority._('Mid', AppColors.priorityMid);
  static final low = Priority._('Low', AppColors.priorityLow);

  /// Get all priority levels
  static List<Priority> getAll() {
    return [low, mid, high];
  }

  /// Get the priority level by its label
  static Priority fromJson(String json) {
    switch (json.toLowerCase()) {
      case 'low':
        return low;
      case 'medium':
      case 'mid':
        return mid;
      case 'high':
        return high;
      default:
        return low;
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
