import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory Admin.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;

    return Admin(
      id: data['id'] as String,
      name: data['name'] as String,
      username: data['username'] as String,
      imageUrl: data['imageUrl'] as String,
      followers: data['followers'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'imageUrl': imageUrl,
      'followers': followers,
    };
  }
}
