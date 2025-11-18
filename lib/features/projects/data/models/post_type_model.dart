import 'package:blocnet/app/theme.dart';
import 'package:flutter/material.dart';

class PostType {
  final String label;
  final Color color;
  final IconData icon;

  const PostType._(this.label, this.color, this.icon);

  // Define the different post types
  static final update = PostType._('Update', AppColors.primary500, Icons.article);
  static final announcement = PostType._('Announcement', AppColors.primary400, Icons.campaign);
  static final urgent = PostType._('Urgent', AppColors.error500, Icons.priority_high);

  /// Get all post types
  static List<PostType> getAll() {
    return [update, announcement, urgent];
  }

  /// Get the post type by its label
  static PostType fromJson(String json) {
    switch (json.toLowerCase()) {
      case 'update':
        return update;
      case 'announcement':
        return announcement;
      case 'urgent':
        return urgent;
      default:
        throw ArgumentError('Invalid post type: $json');
    }
  }

  /// Serialize the post type to JSON
  String toJson() {
    return label;
  }

  /// Override toString to return the label
  @override
  String toString() {
    return label;
  }
}
