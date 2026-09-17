/// What a shared or notification link points at.
enum ContentLinkKind { update, gem, communityPost }

/// A link to one piece of content: `/updates/<id>`, `/projects/<id>`
/// (or `/gems/<id>`), `/community/<id>` (or `/community/posts/<id>`).
class ContentLink {
  const ContentLink(this.kind, this.id);

  final ContentLinkKind kind;
  final String id;

  /// Gems sub-tab paths, which are routes rather than gem ids.
  static const Set<String> _gemViews = {'board', 'hunters'};

  static ContentLink? parse(String path) {
    final segments =
        path.split('/').where((segment) => segment.isNotEmpty).toList();
    if (segments.length < 2) return null;
    final head = segments.first.toLowerCase();
    final rest = segments.sublist(1);
    switch (head) {
      case 'updates':
        return _single(ContentLinkKind.update, rest);
      case 'projects':
        return _single(ContentLinkKind.gem, rest);
      case 'gems':
        if (_gemViews.contains(rest.first.toLowerCase())) return null;
        return _single(ContentLinkKind.gem, rest);
      case 'community':
        final ids =
            rest.first.toLowerCase() == 'posts' ? rest.sublist(1) : rest;
        return _single(ContentLinkKind.communityPost, ids);
    }
    return null;
  }

  static ContentLink? _single(ContentLinkKind kind, List<String> rest) {
    if (rest.length != 1) return null;
    return ContentLink(kind, rest.first);
  }

  @override
  bool operator ==(Object other) =>
      other is ContentLink && other.kind == kind && other.id == id;

  @override
  int get hashCode => Object.hash(kind, id);

  @override
  String toString() => 'ContentLink($kind, $id)';
}
