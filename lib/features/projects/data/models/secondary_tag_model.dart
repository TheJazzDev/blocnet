enum SecondaryTag {
  launching("Launching"),
  ido("IDO"),
  airdrops("Airdrops"),
  mining("Mining"),
  partnership("Partnership"),
  governance("Governance"),
  staking("Staking"),
  tokenBurn("Token Burn"),
  farming("Farming"),
  nft("NFT"),
  trading("Trading"),
  icoIdo("ICO/IDO"),
  gaming("Gaming"),
  wallet("Wallet"),
  security("Security"),
  metaverse("Metaverse");

  final String name;
  const SecondaryTag(this.name);

  /// Method to get all tag names
  static List<String> getAll() {
    return SecondaryTag.values.map((e) => e.name).toList();
  }

  /// Convert enum value to a JSON string
  String toJson() {
    return name;
  }

  /// Create an enum value from a JSON string
  static SecondaryTag fromJson(String json) {
    return SecondaryTag.values.firstWhere(
      (e) => e.name == json,
      orElse: () => throw ArgumentError('Invalid SecondaryTag: $json'),
    );
  }

  @override
  String toString() {
    return name;
  }
}
