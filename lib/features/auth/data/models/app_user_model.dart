import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String email;
  final String? displayName;
  final String? photoURL;
  final String? bio;
  final List<String> followedProjectIds;
  final List<String> savedPostIds;
  final DateTime createdAt;
  final DateTime lastActive;
  final bool isAdmin;
  final List<String> adminProjectIds;
  final Map<String, dynamic> settings;

  AppUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoURL,
    this.bio,
    List<String>? followedProjectIds,
    List<String>? savedPostIds,
    required this.createdAt,
    required this.lastActive,
    this.isAdmin = false,
    List<String>? adminProjectIds,
    Map<String, dynamic>? settings,
  })  : followedProjectIds = followedProjectIds ?? [],
        savedPostIds = savedPostIds ?? [],
        adminProjectIds = adminProjectIds ?? [],
        settings = settings ?? {};

  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoURL,
    String? bio,
    List<String>? followedProjectIds,
    List<String>? savedPostIds,
    DateTime? createdAt,
    DateTime? lastActive,
    bool? isAdmin,
    List<String>? adminProjectIds,
    Map<String, dynamic>? settings,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      bio: bio ?? this.bio,
      followedProjectIds: followedProjectIds ?? this.followedProjectIds,
      savedPostIds: savedPostIds ?? this.savedPostIds,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      isAdmin: isAdmin ?? this.isAdmin,
      adminProjectIds: adminProjectIds ?? this.adminProjectIds,
      settings: settings ?? this.settings,
    );
  }

  factory AppUser.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;

    return AppUser(
      id: snapshot.id,
      email: data['email'] as String,
      displayName: data['displayName'] as String?,
      photoURL: data['photoURL'] as String?,
      bio: data['bio'] as String?,
      followedProjectIds:
          (data['followedProjectIds'] as List?)?.cast<String>() ?? [],
      savedPostIds: (data['savedPostIds'] as List?)?.cast<String>() ?? [],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastActive: (data['lastActive'] as Timestamp).toDate(),
      isAdmin: data['isAdmin'] as bool? ?? false,
      adminProjectIds:
          (data['adminProjectIds'] as List?)?.cast<String>() ?? [],
      settings: data['settings'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'bio': bio,
      'followedProjectIds': followedProjectIds,
      'savedPostIds': savedPostIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActive': Timestamp.fromDate(lastActive),
      'isAdmin': isAdmin,
      'adminProjectIds': adminProjectIds,
      'settings': settings,
    };
  }

  bool isFollowingProject(String projectId) {
    return followedProjectIds.contains(projectId);
  }

  bool hasPostSaved(String postId) {
    return savedPostIds.contains(postId);
  }

  bool isAdminOfProject(String projectId) {
    return isAdmin && adminProjectIds.contains(projectId);
  }
}
