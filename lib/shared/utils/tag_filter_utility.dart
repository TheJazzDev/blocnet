class TagFilterUtility {
  static Set<String> extractTags<T>(List<T> items, String Function(T) getTag) {
    return items.map(getTag).toSet();
  }

  static List<T> applyFilters<T>(
      List<T> items, Set<String> selectedFilters, String Function(T) getTag) {
    if (selectedFilters.isEmpty) return List.from(items);
    return items
        .where((item) => selectedFilters.contains(getTag(item)))
        .toList();
  }

  static void toggleTag(
      String tag, Set<String> selectedFilters, Set<String> allTags) {
    if (tag == 'All') {
      selectedFilters.clear();
    } else if (selectedFilters.contains(tag)) {
      selectedFilters.remove(tag);
      allTags.add(tag);
    } else {
      selectedFilters.add(tag);
      allTags.remove(tag);
    }
  }
}
