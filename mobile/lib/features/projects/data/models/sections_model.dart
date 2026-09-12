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

  /// Everything on the platform. Labelled "General" in the app, which is the
  /// name members already know it by.
  static const explore = Section("explore", "General");

  static const yourProjects = Section("your_projects", "My Gems");
  static const discoverProjects = Section("discover_projects", "Discover Gems");

  /// The tabs Home shows, in order.
  static const List<Section> homeTabs = [forYou, following, explore];

  static const List<Section> all = [
    forYou,
    following,
    explore,
    yourProjects,
    discoverProjects,
  ];
}
