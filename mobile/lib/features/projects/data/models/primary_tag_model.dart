enum PrimaryTag {
  none('None'),
  core('Core'),
  solana('Solana'),
  ethereum('Ethereum'),
  iceOpenNetwork('Ice Open Network'),
  telegramNetwork('Telegram Network'),
  binanceSmartChain('Binance Smart Chain');

  /// Display name for each tag
  final String displayName;

  /// Constructor to assign the display name
  const PrimaryTag(this.displayName);

  /// Get all tag display names
  static List<String> getAll() {
    return PrimaryTag.values
        .where((e) => e != PrimaryTag.none)
        .map((e) => e.displayName)
        .toList();
  }

  /// Find a tag by its display name
  static PrimaryTag fromJson(String json) {
    final normalized = json.trim().toLowerCase();
    return PrimaryTag.values.firstWhere(
      (tag) => tag.displayName.toLowerCase() == normalized,
      orElse: () => PrimaryTag.none,
    );
  }

  /// Serialize the tag to JSON
  String toJson() {
    return displayName;
  }

  /// Override toString to return the display name
  @override
  String toString() {
    return displayName;
  }

  /// Get the identifier (abbreviation) for each tag
  String get identifier {
    switch (this) {
      case PrimaryTag.none:
        return 'none';
      case PrimaryTag.ethereum:
        return 'eth';
      case PrimaryTag.binanceSmartChain:
        return 'bsc';
      case PrimaryTag.core:
        return 'core';
      case PrimaryTag.solana:
        return 'sol';
      case PrimaryTag.iceOpenNetwork:
        return 'ion';
      case PrimaryTag.telegramNetwork:
        return 'ton';
    }
  }
}
