class Admin {
  final String id;
  final String name;
  final String username;
  final String imageUrl;
  final int followers;

  Admin({
    required this.id,
    required this.name,
    required this.username,
    required this.imageUrl,
    required this.followers,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'imageUrl': imageUrl,
      'followers': followers,
    };
  }

  factory Admin.fromApi(Map<String, dynamic> json) {
    final id = (json['id'] ?? json['authorId'] ?? '').toString();
    final name = (json['name'] ?? json['displayName'] ?? 'Admin').toString();
    final username = (json['username'] ??
            '@${id.substring(0, id.length >= 6 ? 6 : id.length)}')
        .toString();
    final imageUrl = (json['imageUrl'] ??
            json['avatarUrl'] ??
            'https://placehold.co/80x80/png')
        .toString();
    final followersRaw = json['followers'];
    final followers = followersRaw is int
        ? followersRaw
        : int.tryParse(followersRaw?.toString() ?? '') ?? 0;

    return Admin(
      id: id,
      name: name,
      username: username,
      imageUrl: imageUrl,
      followers: followers,
    );
  }
}
