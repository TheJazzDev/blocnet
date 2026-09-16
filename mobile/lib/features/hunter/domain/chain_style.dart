import 'package:blocnet/app/theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// How a gem's chain is drawn on the Hub: the short chip label, the chip
/// colour, and the two ends of the monogram gradient.
///
/// Projects have no logo column, so a gem is shown as a two-letter monogram
/// on a gradient of its chain's hue. Mapping from the design's spec table.
@immutable
class ChainStyle {
  const ChainStyle({
    required this.label,
    required this.color,
    required this.chipBackground,
    required this.gradient,
  });

  /// Upper-case chip text, e.g. `TELEGRAM` for "Telegram Network".
  final String label;

  /// Chip text colour.
  final Color color;

  /// Chip ground: [color] at 12%, or zinc for an unknown chain.
  final Color chipBackground;

  /// Monogram gradient, light to deep.
  final List<Color> gradient;

  static const double _chipAlpha = 0.12;

  static ChainStyle _known(String label, Color color, Color deep) {
    return ChainStyle(
      label: label,
      color: color,
      chipBackground: color.withValues(alpha: _chipAlpha),
      gradient: [color, deep],
    );
  }

  /// Resolves a primary tag (or backend `chain`) to its style. Unknown tags
  /// keep their own name, upper-cased, on a neutral chip.
  static ChainStyle forTag(String tag) {
    final key = tag.trim().toLowerCase();
    switch (key) {
      case 'core':
      case 'core dao':
        return _known('CORE', AppColors.chainCore, AppColors.chainCoreDeep);
      case 'telegram':
      case 'telegram network':
      case 'ton':
        return _known(
          'TELEGRAM',
          AppColors.chainTelegram,
          AppColors.chainTelegramDeep,
        );
      case 'solana':
        return _known(
            'SOLANA', AppColors.chainSolana, AppColors.chainSolanaDeep);
      case 'ethereum':
        return _known(
          'ETHEREUM',
          AppColors.chainEthereum,
          AppColors.chainEthereumDeep,
        );
      case 'bsc':
      case 'binance':
      case 'binance smart chain':
      case 'bnb chain':
        return _known('BSC', AppColors.chainBsc, AppColors.chainBscDeep);
      case 'ice':
      case 'ice open network':
        return _known('ICE', AppColors.chainIce, AppColors.chainIceDeep);
    }
    return ChainStyle(
      label: key.isEmpty ? '' : tag.trim().toUpperCase(),
      color: AppColors.zincMuted,
      chipBackground: AppColors.borderSubtle,
      gradient: const [AppColors.chainNeutral, AppColors.borderSubtle],
    );
  }
}

/// Two letters for a gem: the initials of its first two parts. A single word
/// splits where letters meet digits or a capital ("Bless50ing" → "B5",
/// "OrbitLend" → "OL"); otherwise its first two letters.
String gemMonogram(String name) {
  var parts =
      name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) {
    final only = parts.first;
    parts = RegExp(r'[A-Z]?[a-z]+|[A-Z]+(?![a-z])|\d+|[^A-Za-z\d]+')
        .allMatches(only)
        .map((m) => m.group(0)!)
        .toList();
    if (parts.length < 2) {
      return only.substring(0, only.length >= 2 ? 2 : 1).toUpperCase();
    }
  }
  return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
}
