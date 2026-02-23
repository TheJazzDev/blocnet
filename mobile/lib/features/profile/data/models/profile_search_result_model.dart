class ProfileSearchResult {
  const ProfileSearchResult({
    required this.id,
    required this.displayName,
    required this.username,
    required this.avatarUrl,
    required this.followersCount,
    required this.roles,
  });

  final String id;
  final String? displayName;
  final String? username;
  final String? avatarUrl;
  final int followersCount;
  final List<String> roles;

  bool get isHunter =>
      roles.map((role) => role.toLowerCase()).contains('hunter');

  String get label {
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) return name;

    final handle = username?.trim();
    if (handle != null && handle.isNotEmpty) {
      return handle.startsWith('@') ? handle : '@$handle';
    }

    return id;
  }

  String get handle {
    final raw = username?.trim();
    if (raw == null || raw.isEmpty) return '';
    return raw.startsWith('@') ? raw : '@$raw';
  }

  factory ProfileSearchResult.fromApi(Map<String, dynamic> json) {
    final roles = (json['roles'] as List? ?? const [])
        .map((entry) => entry.toString().trim().toLowerCase())
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);

    return ProfileSearchResult(
      id: json['id']?.toString() ?? '',
      displayName: json['displayName']?.toString(),
      username: json['username']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      followersCount: int.tryParse(json['followersCount']?.toString() ?? '') ?? 0,
      roles: roles,
    );
  }
}
