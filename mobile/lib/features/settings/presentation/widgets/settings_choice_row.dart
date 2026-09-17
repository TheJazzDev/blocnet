import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:flutter/material.dart';

/// A settings row with a title on the left and outlined choice pills on the
/// right. The chosen pill is tinted with the space accent.
class SettingsChoiceRow<T> extends StatelessWidget {
  const SettingsChoiceRow({
    super.key,
    required this.icon,
    required this.title,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final Map<T, String> options;
  final T selected;

  /// Null disables the row.
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    final tint = AppColors.primary400;

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.lg, vertical: AppSpace.md),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.12),
                borderRadius: AppRadius.sm,
              ),
              child: Icon(icon, size: AppIcon.sm, color: tint),
            ),
            AppSpace.wGapMd,
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.body(AppColors.textPrimary,
                    weight: AppText.semibold),
              ),
            ),
            for (final entry in options.entries) ...[
              AppSpace.wGapXs,
              _ChoicePill(
                label: entry.value,
                selected: entry.key == selected,
                onTap: enabled ? () => onChanged!(entry.key) : null,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tint = AppColors.primary400;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          constraints: const BoxConstraints(minHeight: 32, minWidth: 44),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
          decoration: BoxDecoration(
            color:
                selected ? tint.withValues(alpha: 0.12) : AppColors.bgElevated,
            borderRadius: AppRadius.full,
            border: Border.all(
              color: selected
                  ? tint.withValues(alpha: 0.45)
                  : AppColors.borderMuted,
            ),
          ),
          child: Text(
            label,
            style: AppText.label(
              selected ? tint : AppColors.textMuted,
              weight: selected ? AppText.bold : AppText.medium,
            ),
          ),
        ),
      ),
    );
  }
}
