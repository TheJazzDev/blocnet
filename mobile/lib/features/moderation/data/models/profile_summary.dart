class ProfileSummary {
  final String id;
  final String? username;
  final String? displayName;
  final String? avatarUrl;

  const ProfileSummary({
    required this.id,
    this.username,
    this.displayName,
    this.avatarUrl,
  });

  factory ProfileSummary.fromApi(Map<String, dynamic> json) {
    return ProfileSummary(
      id: json['id'] as String,
      username: json['username'] as String?,
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  String get name => displayName ?? username ?? 'Unknown User';
}
