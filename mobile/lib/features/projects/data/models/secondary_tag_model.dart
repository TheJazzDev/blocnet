class SecondaryTag {
  const SecondaryTag({required this.id, required this.name, this.slug = ''});

  final String id;
  final String name;
  final String slug;

  factory SecondaryTag.fromApi(Map<String, dynamic> json) {
    return SecondaryTag(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
    );
  }

  factory SecondaryTag.fromJson(String json) {
    final value = json.trim();
    return SecondaryTag(
      id: '',
      name: value,
      slug: _toSlug(value),
    );
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

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SecondaryTag &&
        other.id.toLowerCase() == id.toLowerCase() &&
        other.name.toLowerCase() == name.toLowerCase();
  }

  @override
  int get hashCode => Object.hash(id.toLowerCase(), name.toLowerCase());
}
