import 'package:blocnet/features/community/data/models/community_moderation_models.dart';
import 'package:blocnet/features/community/data/repositories/community_moderation_api_repository.dart';
import 'package:blocnet/features/community/presentation/widgets/community_content_moderation_sheet.dart';
import 'package:blocnet/services/api/api_error.dart';
import 'package:blocnet/services/community/community_posts_store.dart';
import 'package:blocnet/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Applies a moderator's decision to a post, updates what the app holds, and
/// says what happened. Returns whether it worked.
Future<bool> applyPostModeration(
  BuildContext context, {
  required CommunityModerationApiRepository repository,
  required String postId,
  required CommunityContentModerationDecision decision,
}) async {
  final store = context.read<CommunityPostsStore>();
  try {
    await repository.moderateCommunityPostStatus(
      postId: postId,
      status: decision.status,
      reason: decision.reason,
    );
    if (decision.status == CommunityContentModerationStatus.active) {
      await store.refreshPosts();
    } else {
      store.removePost(postId);
    }
    if (context.mounted) {
      AppSnackbar.showSuccess(context, _done(decision.status, 'Post'));
    }
    return true;
  } catch (error) {
    if (context.mounted) {
      AppSnackbar.showError(
        context,
        describeApiError(error, fallback: 'Could not moderate this post'),
      );
    }
    return false;
  }
}

/// Applies a moderator's decision to a comment and reloads its thread.
Future<bool> applyCommentModeration(
  BuildContext context, {
  required CommunityModerationApiRepository repository,
  required String postId,
  required String commentId,
  required CommunityContentModerationDecision decision,
}) async {
  final store = context.read<CommunityPostsStore>();
  try {
    await repository.moderateCommunityCommentStatus(
      commentId: commentId,
      status: decision.status,
      reason: decision.reason,
    );
    await store.fetchComments(postId, force: true);
    if (context.mounted) {
      AppSnackbar.showSuccess(context, _done(decision.status, 'Comment'));
    }
    return true;
  } catch (error) {
    if (context.mounted) {
      AppSnackbar.showError(
        context,
        describeApiError(error, fallback: 'Could not moderate this comment'),
      );
    }
    return false;
  }
}

String _done(CommunityContentModerationStatus status, String target) =>
    switch (status) {
      CommunityContentModerationStatus.active => '$target restored',
      CommunityContentModerationStatus.hidden => '$target hidden',
      CommunityContentModerationStatus.archived => '$target archived',
    };
