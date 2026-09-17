import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/system_alerts/presentation/widgets/system_alert_ui.dart';
import 'package:flutter/material.dart';

class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.borderMuted,
          borderRadius: AppRadius.full,
        ),
      ),
    );
  }
}

/// Label/value rows in one card, hairline between, each with a copy icon.
class DetailFieldsCard extends StatelessWidget {
  const DetailFieldsCard({
    super.key,
    required this.fields,
    required this.onCopy,
  });

  final List<(String, String)> fields;
  final void Function(String label, String value) onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: alertCardDecoration(),
      child: Column(
        children: [
          for (var i = 0; i < fields.length; i++) ...[
            if (i > 0) Divider(height: 1, color: AppColors.borderSubtle),
            _row(fields[i].$1, fields[i].$2),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpace.lg, AppSpace.md, AppSpace.xs, AppSpace.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(), style: alertCaps(AppColors.textFaint)),
                const SizedBox(height: AppSpace.hair),
                SelectableText(
                  value,
                  style: AppText.label(AppColors.textSecondary,
                      weight: AppText.semibold),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Copy $label',
            onPressed: () => onCopy(label, value),
            icon: Icon(
              Icons.copy_rounded,
              size: AppIcon.sm,
              color: AppColors.textFaint,
            ),
          ),
        ],
      ),
    );
  }
}

class MetadataBlock extends StatelessWidget {
  const MetadataBlock({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppSpace.allMd,
      decoration: BoxDecoration(
        color: AppColors.bgBase,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: SelectableText(
        text,
        style: AppText.caption(AppColors.textMuted).copyWith(
          fontFamily: 'monospace',
          height: 1.4,
        ),
      ),
    );
  }
}

/// 44px button: filled accent, or dark outlined.
class AlertButton extends StatelessWidget {
  const AlertButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.filled = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.primary500;
    final foreground = filled
        ? (accent.computeLuminance() > 0.4 ? Colors.black : Colors.white)
        : AppColors.textPrimary;
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size.fromHeight(44),
        backgroundColor: filled ? accent : AppColors.bgElevated,
        foregroundColor: foreground,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
        side: filled ? null : BorderSide(color: AppColors.borderMuted),
        textStyle: AppText.label(foreground, weight: AppText.bold),
      ),
      icon: icon == null ? null : Icon(icon, size: AppIcon.sm),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}
