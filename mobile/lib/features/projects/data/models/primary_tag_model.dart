class PrimaryTag {
  const PrimaryTag({required this.id, required this.name, this.slug = ''});

  final String id;
  final String name;
  final String slug;

  static const none = PrimaryTag(id: '', name: 'None', slug: 'none');

  factory PrimaryTag.fromApi(Map<String, dynamic> json) {
    return PrimaryTag(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
    );
  }

  factory PrimaryTag.fromJson(String json) {
    final value = json.trim();
    if (value.isEmpty) return none;
    return PrimaryTag(id: '', name: value, slug: _toSlug(value));
  }

  static String _toSlug(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-');
  }

  String toJson() => name;

  String get identifier {
    if (slug.isNotEmpty) return slug;
    return _toSlug(name);
  }

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PrimaryTag &&
        other.id.toLowerCase() == id.toLowerCase() &&
        other.name.toLowerCase() == name.toLowerCase();
  }

  @override
  int get hashCode => Object.hash(id.toLowerCase(), name.toLowerCase());
}
