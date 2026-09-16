import 'dart:async';

import 'package:blocnet/features/projects/data/models/admin_model.dart';
import 'package:blocnet/features/projects/data/models/primary_tag_model.dart';
import 'package:blocnet/features/projects/data/models/priority_model.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/services/api/api_client.dart';
import 'package:blocnet/services/projects/update_reactions_repository.dart';

/// An update as the feed would hand it to a card.
Update reactionUpdate({
  String id = 'update-1',
  String title = 'KYC opens for Phase 2',
  int likesCount = 412,
  int bookmarksCount = 7,
  bool likedByMe = false,
  bool bookmarkedByMe = false,
}) {
  return Update(
    id: id,
    title: title,
    content: 'Use the same wallet you mined with.',
    description: 'Use the same wallet you mined with.',
    adminId: 'author-1',
    projectId: 'project-1',
    priority: Priority.mid,
    createdAt: DateTime(2026, 9, 12),
    admin: Admin(
      id: 'author-1',
      name: 'Jazzdev',
      username: 'jazzdev',
      imageUrl: '',
      followers: 12,
      roles: const ['hunter'],
    ),
    project: Project(
      id: 'project-1',
      logo: '',
      name: 'Core Mines',
      details: 'Mining on Core',
      adminId: 'author-1',
      createdAt: DateTime(2026, 9, 1),
      primaryTagId: 'tag-1',
      primaryTag: const PrimaryTag(id: 'tag-1', name: 'Core', slug: 'core'),
      description: 'Mining on Core',
      followersCount: 10,
    ),
    likesCount: likesCount,
    bookmarksCount: bookmarksCount,
    likedByMe: likedByMe,
    bookmarkedByMe: bookmarkedByMe,
    secondaryTagIds: const [],
    secondaryTags: const [],
  );
}

/// A repository whose answers the test controls. Each write can be held open
/// with [likeGate] / [bookmarkGate] so the optimistic state can be observed.
class FakeReactionsRepository extends UpdateReactionsRepository {
  FakeReactionsRepository() : super(apiClient: ApiClient());

  int serverLikes = 0;
  int serverBookmarks = 0;
  bool failWrites = false;
  bool failSaved = false;
  bool failImport = false;
  Completer<void>? likeGate;
  Completer<void>? bookmarkGate;
  List<Update> saved = [];

  final List<String> calls = [];
  final List<Map<String, List<String>>> imports = [];

  @override
  Future<UpdateLikeResult> setLiked(String updateId, bool liked) async {
    calls.add('${liked ? 'PUT' : 'DELETE'} like $updateId');
    await likeGate?.future;
    if (failWrites) throw ApiException('offline', statusCode: 503);
    return UpdateLikeResult(liked: liked, likesCount: serverLikes);
  }

  @override
  Future<UpdateBookmarkResult> setBookmarked(
    String updateId,
    bool bookmarked,
  ) async {
    calls.add('${bookmarked ? 'PUT' : 'DELETE'} bookmark $updateId');
    await bookmarkGate?.future;
    if (failWrites) throw ApiException('offline', statusCode: 503);
    return UpdateBookmarkResult(
      bookmarked: bookmarked,
      bookmarksCount: serverBookmarks,
    );
  }

  @override
  Future<List<Update>> fetchSavedUpdates({
    int limit = 100,
    int offset = 0,
  }) async {
    calls.add('GET saved');
    if (failSaved) throw ApiException('offline', statusCode: 503);
    return List.of(saved);
  }

  @override
  Future<void> importLocalReactions({
    required List<String> likedUpdateIds,
    required List<String> bookmarkedUpdateIds,
  }) async {
    calls.add('POST import');
    if (failImport) throw ApiException('offline', statusCode: 503);
    imports.add({
      'liked': likedUpdateIds,
      'bookmarked': bookmarkedUpdateIds,
    });
  }
}
