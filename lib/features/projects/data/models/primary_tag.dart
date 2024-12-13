enum PrimaryTag {
  ethereum('Ethereum (ETH)'),
  binanceSmartChain('Binance Smart Chain (BSC)'),
  core('Core (CORE)'),
  solana('Solana (SOL)'),
  iceOpenNetwork('Ice Open Network (ION)'),
  telegramNetwork('Telegram Network (TON)');

  // The display name for each tag
  final String displayName;

  // Constructor to assign the display name
  const PrimaryTag(this.displayName);

  // Method to get all tag display names
  static List<String> getTags() {
    return PrimaryTag.values.map((e) => e.displayName).toList();
  }

  // Method to find a tag by its display name
  static PrimaryTag fromString(String displayName) {
    return PrimaryTag.values.firstWhere(
      (tag) => tag.displayName == displayName,
      orElse: () => throw ArgumentError('Invalid tag: $displayName'),
    );
  }

  // Override toString to return the display name
  @override
  String toString() {
    return displayName;
  }

  // Optional: Get the identifier (abbreviation) for each tag
  String get identifier {
    switch (this) {
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
      default:
        return '';
    }
  }
}
