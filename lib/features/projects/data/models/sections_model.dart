class Section {
  final String identifier;
  final String label;

  const Section(this.identifier, this.label);

  @override
  String toString() => label;
}

class Sections {
  static const forYou = Section("for_you", "For You");
  static const explore = Section("explore", "Explore");
  static const yourProjects = Section("your_projects", "Your Projects");
  static const discoverProjects = Section("discover_projects", "Discover Projects");

  static const List<Section> all = [
    forYou,
    explore,
    yourProjects,
    discoverProjects,
  ];
}
