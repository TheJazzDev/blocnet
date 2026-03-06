import 'package:blocnet/features/community/data/models/community_post_comment_model.dart';

class CommunityCommentSyncHelper {
  const CommunityCommentSyncHelper._();

  static CommunityPostComment? parseRealtimeComment(
    String postId,
    Map<String, dynamic> newRecord,
  ) {
    try {
      final record = Map<String, dynamic>.from(newRecord);
      final status = (record['status'] ?? 'active').toString().toLowerCase();
      if (status != 'active') {
        return null;
      }
      record['postId'] = record['postId'] ?? postId;
      final parsed = CommunityPostComment.fromApi(record);
      if (parsed.id.trim().isEmpty || parsed.postId.trim().isEmpty) {
        return null;
      }
      return parsed;
    } catch (_) {
      return null;
    }
  }

  static List<CommunityPostComment> mergeComments(
    List<CommunityPostComment> base,
    List<CommunityPostComment> incoming,
  ) {
    final byId = <String, CommunityPostComment>{};
    for (final item in base) {
      if (item.id.trim().isEmpty) continue;
      byId[item.id] = item;
    }

    for (final item in incoming) {
      if (item.id.trim().isEmpty) continue;
      final existing = byId[item.id];
      if (existing == null) {
        byId[item.id] = item;
        continue;
      }
      byId[item.id] = _mergeComment(existing, item);
    }

    return sortComments(byId.values.toList(growable: false));
  }

  static List<CommunityPostComment> sortComments(
    List<CommunityPostComment> items,
  ) {
    items.sort((a, b) {
      final byTime = a.createdAt.compareTo(b.createdAt);
      if (byTime != 0) return byTime;
      return a.id.compareTo(b.id);
    });
    return items;
  }

  static CommunityPostComment _mergeComment(
    CommunityPostComment existing,
    CommunityPostComment incoming,
  ) {
    return CommunityPostComment(
      id: existing.id,
      postId: existing.postId,
      authorId: incoming.authorId.trim().isNotEmpty
          ? incoming.authorId
          : existing.authorId,
      content: incoming.content.trim().isNotEmpty
          ? incoming.content
          : existing.content,
      createdAt: incoming.createdAt.isBefore(existing.createdAt)
          ? incoming.createdAt
          : existing.createdAt,
      updatedAt: incoming.updatedAt.isAfter(existing.updatedAt)
          ? incoming.updatedAt
          : existing.updatedAt,
      likesCount: incoming.likesCount > 0 ||
              incoming.updatedAt.isAfter(existing.updatedAt)
          ? incoming.likesCount
          : existing.likesCount,
      isLiked: incoming.isLiked != existing.isLiked ||
              incoming.likesCount != existing.likesCount ||
              incoming.updatedAt.isAfter(existing.updatedAt)
          ? incoming.isLiked
          : existing.isLiked,
      admin: incoming.admin ?? existing.admin,
      replyToId: incoming.replyToId ?? existing.replyToId,
      replyToData: incoming.replyToData ?? existing.replyToData,
    );
  }
}
