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

  @override
  String toString() {
    return name;
  }
}
