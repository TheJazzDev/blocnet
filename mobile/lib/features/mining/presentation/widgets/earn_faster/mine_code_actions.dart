import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/mining/presentation/mine_palette.dart';
import 'package:blocnet/features/mining/presentation/widgets/mine_sections.dart';
import 'package:blocnet/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

/// The referral link a shared code opens (handled by `DeepLinkService`).
String mineReferralLink(String code) => 'https://blocnet.app/ref/$code';

/// The member's code in its box, then `Share code` (primary) and `Copy`.
class MineCodeActions extends StatelessWidget {
  const MineCodeActions({super.key, required this.code});

  /// Null until the referral summary loads.
  final String? code;

  Future<void> _share(BuildContext context, String code) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: 'Join me on Blocnet with my code $code\n'
              '${mineReferralLink(code)}',
          subject: 'Join me on Blocnet',
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      AppSnackbar.showError(context, 'Unable to open share options right now.');
    }
  }

  Future<void> _copy(BuildContext context, String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!context.mounted) return;
    AppSnackbar.showSuccess(context, 'Code copied');
  }

  @override
  Widget build(BuildContext context) {
    final value = code;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          margin: const EdgeInsets.only(top: AppSpace.lg),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.lg,
            vertical: AppSpace.md,
          ),
          decoration: mineTileDecoration(
            ground: MinePalette.raised,
            radius: AppRadius.md,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.key_rounded,
                  size: AppIcon.md, color: MinePalette.faint),
              const SizedBox(width: AppSpace.md),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value ?? '········',
                    style: AppText.headline(MinePalette.accentSoft)
                        .merge(AppText.tabular)
                        .copyWith(letterSpacing: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.md),
        Row(
          children: [
            Expanded(
              child: _Button(
                key: const ValueKey('mine-share-code'),
                label: 'Share code',
                icon: Icons.ios_share_rounded,
                filled: true,
                onTap: value == null ? null : () => _share(context, value),
              ),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: _Button(
                key: const ValueKey('mine-copy-code'),
                label: 'Copy',
                icon: Icons.copy_rounded,
                filled: false,
                onTap: value == null ? null : () => _copy(context, value),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Button extends StatelessWidget {
  const _Button({
    super.key,
    required this.label,
    required this.filled,
    required this.onTap,
    this.icon,
  });

  final String label;
  final IconData? icon;
  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ground = filled ? MinePalette.accent : MinePalette.raised;
    final fg = filled
        ? (ThemeData.estimateBrightnessForColor(ground) == Brightness.dark
            ? Colors.white
            : Colors.black)
        : MinePalette.text;
    // The old referral screen's pair: two equal buttons, 44 tall.
    return Material(
      color: ground,
      borderRadius: AppRadius.md,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.md,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
          decoration: filled
              ? null
              : BoxDecoration(
                  borderRadius: AppRadius.md,
                  border: Border.all(color: MinePalette.strongEdge),
                ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: AppIcon.sm, color: fg),
                const SizedBox(width: AppSpace.sm),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.label(fg, weight: AppText.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
