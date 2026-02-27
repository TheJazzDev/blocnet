enum FeedViewMode { list, card }

extension FeedViewModeParsing on FeedViewMode {
  static FeedViewMode fromStorage(String? value) {
    return value == FeedViewMode.card.name
        ? FeedViewMode.card
        : FeedViewMode.list;
  }
}
