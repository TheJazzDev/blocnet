import 'dart:async';

import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/community/data/models/community_moderation_models.dart';
import 'package:blocnet/features/community/data/models/community_post_comment_model.dart';
import 'package:blocnet/features/community/data/models/community_post_model.dart';
import 'package:blocnet/features/community/data/models/community_topic.dart';
import 'package:blocnet/features/community/data/repositories/community_moderation_api_repository.dart';
import 'package:blocnet/features/community/data/repositories/community_posts_api_repository.dart';
import 'package:blocnet/features/levels/data/models/user_level_model.dart';
import 'package:blocnet/features/projects/data/models/admin_model.dart';
import 'package:blocnet/services/api/api_client.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/community/community_posts_store.dart';
import 'package:blocnet/services/users/blocks_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Sets a phone-sized surface (logical [width] × [height]) for one test.
void usePhone(WidgetTester tester, {double width = 375, double height = 812}) {
  tester.view.physicalSize = Size(width * 3, height * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Admin author({
  String id = 'author-1',
  String name = 'Ada Lovelace',
  String username = 'ada',
  List<String> roles = const ['hunter'],
  int? level = 7,
}) {
  return Admin(
    id: id,
    name: name,
    username: username,
    imageUrl: '',
    followers: 0,
    roles: roles,
    currentLevel: level == null
        ? null
        : UserLevelModel.fromApi({
            'id': 'lvl-$level',
            'slug': 'lvl-$level',
            'name': 'Level $level',
            'level': level,
          }),
  );
}

CommunityPost post({
  String id = 'post-1',
  String content = 'Core mainnet snapshot is at 12:00 UTC.',
  Admin? by,
  CommunityTopic topic = CommunityTopic.general,
  bool saved = false,
  bool liked = false,
  int likes = 3,
  int comments = 2,
  CommunityContentModerationStatus status =
      CommunityContentModerationStatus.active,
}) {
  final a = by ?? author();
  return CommunityPost(
    id: id,
    authorId: a.id,
    topic: topic,
    content: content,
    createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    updatedAt: DateTime.now(),
    likesCount: likes,
    commentsCount: comments,
    isLiked: liked,
    isBookmarked: saved,
    status: status,
    admin: a,
  );
}

CommunityPostComment comment({
  required String id,
  String content = 'Same here, thanks for the heads up.',
  String? replyToId,
  ReplyToData? replyTo,
  Admin? by,
}) {
  final a = by ?? author(id: 'author-$id', name: 'Member $id', roles: []);
  return CommunityPostComment(
    id: id,
    postId: 'post-1',
    authorId: a.id,
    content: content,
    createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
    updatedAt: DateTime.now(),
    likesCount: 1,
    admin: a,
    replyToId: replyToId,
    replyToData: replyTo,
  );
}

/// A posts repository whose calls are scripted by the test.
class FakePostsRepository extends CommunityPostsApiRepository {
  FakePostsRepository() : super(apiClient: ApiClient());

  List<CommunityPost> feed = [];
  Object? feedError;
  List<CommunityPost> bookmarks = [];
  Object? bookmarksError;
  Completer<void>? bookmarksGate;
  int bookmarkCalls = 0;
  final List<String> saved = [];
  final List<String> unsaved = [];
  Object? toggleError;
  CommunityPost? Function(String id)? byId;
  Object? byIdError;

  @override
  Future<List<CommunityPost>> fetchPosts({
    int limit = 100,
    int offset = 0,
    CommunityTopic? topic,
  }) async {
    if (feedError != null) throw feedError!;
    return feed;
  }

  @override
  Future<List<CommunityPost>> fetchBookmarks({
    int limit = 100,
    int offset = 0,
  }) async {
    bookmarkCalls++;
    final gate = bookmarksGate;
    if (gate != null) await gate.future;
    final error = bookmarksError;
    if (error != null) throw error;
    return bookmarks;
  }

  @override
  Future<CommunityPost?> fetchPostById(String postId) async {
    final error = byIdError;
    if (error != null) throw error;
    return byId?.call(postId);
  }

  @override
  Future<CommunityPost?> bookmarkPost(String postId) async {
    if (toggleError != null) throw toggleError!;
    saved.add(postId);
    return null;
  }

  @override
  Future<CommunityPost?> unbookmarkPost(String postId) async {
    if (toggleError != null) throw toggleError!;
    unsaved.add(postId);
    return null;
  }
}

/// A moderation repository for My reports.
class FakeModerationRepository extends CommunityModerationApiRepository {
  FakeModerationRepository() : super(apiClient: ApiClient());

  CommunityModerationReportsPage? page;
  Object? error;
  int myReportCalls = 0;
  int staffListCalls = 0;
  CreateCommunityReportRequest? lastReport;

  @override
  Future<CommunityModerationReportsPage> fetchMyReports({
    int limit = 20,
    int offset = 0,
  }) async {
    myReportCalls++;
    if (error != null) throw error!;
    return page!;
  }

  @override
  Future<CommunityModerationReportsPage> fetchReports({
    int limit = 20,
    int offset = 0,
    String? q,
    CommunityReportStatus? status,
    CommunityReportTargetType? targetType,
  }) async {
    staffListCalls++;
    throw ApiException('Forbidden', statusCode: 403);
  }

  @override
  Future<CommunityModerationReport> createReport(
    CreateCommunityReportRequest request,
  ) async {
    lastReport = request;
    return report(id: 'new');
  }
}

CommunityModerationReport report({
  required String id,
  CommunityReportStatus status = CommunityReportStatus.open,
  String reason = 'Spam or promotional content',
  String? details,
  String? note,
}) {
  return CommunityModerationReport.fromApi({
    'id': id,
    'reporterId': 'me',
    'targetType': 'community_post',
    'targetId': 'post-1',
    'reason': reason,
    'details': details,
    'status': status.apiValue,
    'reviewedAt': status == CommunityReportStatus.open
        ? null
        : DateTime.now().toIso8601String(),
    'resolutionNote': note,
    'createdAt': DateTime.now().toIso8601String(),
    'updatedAt': DateTime.now().toIso8601String(),
  });
}

/// Wraps [child] in the providers community widgets read, with routes that
/// record where the app was sent.
Widget communityHost({
  required Widget child,
  required CommunityPostsStore store,
  List<String>? pushed,
  bool wrapInScaffold = false,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthStore>(
        create: (_) => AuthStore(
          enableSupabaseAuthListener: false,
          supabaseConfiguredOverride: false,
        ),
      ),
      ChangeNotifierProvider<CommunityPostsStore>.value(value: store),
      ChangeNotifierProvider<BlocksStore>(
        create: (_) => BlocksStore(ApiClient()),
      ),
    ],
    child: MaterialApp(
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bgBase,
      ),
      home: wrapInScaffold ? Scaffold(body: child) : child,
      onGenerateRoute: (settings) {
        pushed?.add(settings.name ?? '');
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => Scaffold(body: Text('route ${settings.name}')),
        );
      },
    ),
  );
}
