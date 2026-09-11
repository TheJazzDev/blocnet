import 'package:blocnet/features/levels/data/models/user_level_model.dart';
import 'package:blocnet/shared/utils/user_level_parsing.dart';

class MentionUserModel {
  final String id;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final UserLevelModel? currentLevel;

  MentionUserModel({
    required this.id,
    required this.username,
    this.displayName,
    this.avatarUrl,
    this.currentLevel,
  });

  factory MentionUserModel.fromJson(Map<String, dynamic> json) {
    return MentionUserModel(
      id: json['id'] as String,
      username: json['username'] as String,
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      currentLevel: parseCurrentLevel(json['currentLevel']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
    };
  }
}
