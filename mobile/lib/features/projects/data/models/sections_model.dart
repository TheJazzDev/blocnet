class Section {
  final String identifier;
  final String label;

  const Section(this.identifier, this.label);

  @override
  String toString() => label;
}

class Sections {
  /// Home's default tab for a member whose board is thin: their own gems mixed
  /// with curated ones, so the screen is worth scrolling from day one. See
  /// `FeedBlend`.
  static const forYou = Section("for_you", "For you");

  /// Only the gems the member follows. This is what the feed has always shown
  /// under `forYou`; the tab was mislabelled "Updates", which named the content
  /// type rather than whose it was.
  static const following = Section("following", "Following");

  /// The tabs Home shows, in order.
  /// Order per the approved design: Following leads, because for a member
  /// with a board it is the tab that matters. On day one it is dimmed and
  /// For you opens instead. General ("everything, newest first") was cut:
  /// that job moves to Gems.
  static const List<Section> homeTabs = [following, forYou];

  static const List<Section> all = [forYou, following];
}
