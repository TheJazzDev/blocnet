import 'package:blocnet/services/community/community_posts_store.dart';
import 'package:blocnet/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Saves or unsaves a community post and says which happened.
Future<void> toggleCommunitySave(BuildContext context, String postId) async {
  final store = context.read<CommunityPostsStore>();
  final wasSaved = store.postById(postId)?.isBookmarked ?? false;
  final ok = await store.toggleBookmark(postId);
  if (ok == null || !context.mounted) return;
  if (ok) {
    AppSnackbar.showSuccess(context, wasSaved ? 'Removed from saved' : 'Saved');
  } else {
    AppSnackbar.showError(context, 'Could not update saved');
  }
}
