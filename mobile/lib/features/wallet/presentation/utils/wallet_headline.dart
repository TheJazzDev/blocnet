import 'package:blocnet/features/wallet/data/models/wallet_models.dart';
import 'package:blocnet/features/wallet/presentation/utils/wallet_utils.dart';

/// The one asset whose price is allowed to read as pending: BNT has no
/// market until it launches on BSC. BNB and USDT already move.
const String walletPendingPriceAsset = 'BNT';

/// What the wallet's balance card leads with.
class WalletHeadline {
  const WalletHeadline({
    required this.amount,
    this.otherHoldings,
    this.note,
  });

  /// Big figure: a USD total, or a token amount when nothing has a price.
  final String amount;

  /// Further token holdings when [amount] is a token amount, e.g.
  /// `+ 10 USDT · 0.02 BNB`.
  final String? otherHoldings;

  /// Caveat under the figure, e.g. that BNT is not priced yet.
  final String? note;

  /// Built from the balances the wallet actually holds. A USD figure only
  /// ever sums live prices; an asset without one is shown in its own units
  /// or called out, never valued at a made-up price.
  factory WalletHeadline.from(WalletSnapshot? snapshot) {
    final assets = snapshot?.assets ?? const <WalletAssetBalance>[];
    final held = assets.where((a) => _amount(a.available) > 0).toList();
    final priced = assets.where((a) => isUsdPriceLive(a.priceSource));
    final heldUnpriced =
        held.where((a) => !isUsdPriceLive(a.priceSource)).toList();

    if (priced.isNotEmpty) {
      final total =
          priced.fold<double>(0, (sum, a) => sum + _amount(a.usdValue));
      return WalletHeadline(
        amount: '\$${formatUsd(total.toString())}',
        note: heldUnpriced.isEmpty
            ? null
            : 'Excludes ${_holdings(heldUnpriced)}. ${_pendingReason(heldUnpriced)}',
      );
    }

    if (held.isEmpty) {
      // Nothing held is worth nothing at any price.
      return WalletHeadline(amount: '\$${formatUsd('0')}');
    }

    return WalletHeadline(
      amount: _holding(held.first),
      otherHoldings: held.length > 1 ? '+ ${_holdings(held.skip(1))}' : null,
      note: _pendingReason(held),
    );
  }

  static String _pendingReason(Iterable<WalletAssetBalance> unpriced) {
    final bntOnly = unpriced.every(
      (a) => a.asset.toUpperCase() == walletPendingPriceAsset,
    );
    if (bntOnly) return 'BNT price pending until it launches on BSC.';
    return 'No USD price is available for them right now.';
  }

  static String _holdings(Iterable<WalletAssetBalance> assets) =>
      assets.map(_holding).join(' · ');

  static String _holding(WalletAssetBalance asset) =>
      '${formatTokenAmount(asset.available)} ${asset.asset}';

  static double _amount(String value) => double.tryParse(value.trim()) ?? 0;
}

/// Per-asset USD line when the asset has no live price.
String walletUnpricedLabel(WalletAssetBalance asset) =>
    asset.asset.toUpperCase() == walletPendingPriceAsset
        ? 'Pre-launch'
        : 'No USD price';
