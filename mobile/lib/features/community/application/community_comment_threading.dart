import 'package:blocnet/features/community/data/models/community_post_comment_model.dart';

/// A comment placed in a thread: top-level, or a reply under its parent.
class ThreadedCommunityComment {
  const ThreadedCommunityComment({
    required this.comment,
    this.isNestedReply = false,
  });

  final CommunityPostComment comment;
  final bool isNestedReply;
}

/// Orders [comments] as a thread, one level deep: each top-level comment is
/// followed by its replies, and a reply to a reply sits under the same root.
/// A reply whose parent is not loaded stays top-level (it shows a quote of
/// its parent instead).
List<ThreadedCommunityComment> threadCommunityComments(
  List<CommunityPostComment> comments,
) {
  final byId = {for (final c in comments) c.id: c};

  String? rootOf(CommunityPostComment comment) {
    var current = comment;
    final seen = <String>{current.id};
    while (true) {
      final parentId = current.replyToId?.trim() ?? '';
      final parent = byId[parentId];
      if (parentId.isEmpty || parent == null) {
        return identical(current, comment) ? null : current.id;
      }
      if (!seen.add(parent.id)) return null; // a loop in bad data
      current = parent;
    }
  }

  final roots = <CommunityPostComment>[];
  final repliesByRoot = <String, List<CommunityPostComment>>{};
  for (final comment in comments) {
    final root = rootOf(comment);
    if (root == null) {
      roots.add(comment);
    } else {
      repliesByRoot.putIfAbsent(root, () => []).add(comment);
    }
  }

  return [
    for (final root in roots) ...[
      ThreadedCommunityComment(comment: root),
      for (final reply in repliesByRoot[root.id] ?? const [])
        ThreadedCommunityComment(comment: reply, isNestedReply: true),
    ],
  ];
}
