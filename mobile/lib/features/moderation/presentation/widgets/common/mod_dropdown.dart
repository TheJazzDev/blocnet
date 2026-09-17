import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/moderation/presentation/widgets/common/mod_parts.dart';
import 'package:flutter/material.dart';

/// A labelled 40px dropdown on the dark field background.
class ModDropdown<T> extends StatelessWidget {
  const ModDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final T value;

  /// Value → visible label, in display order.
  final Map<T, String> options;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ModFieldLabel(label),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
          decoration: BoxDecoration(
            color: AppColors.bgElevated,
            borderRadius: AppRadius.md,
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              dropdownColor: AppColors.bgSurface,
              borderRadius: AppRadius.md,
              iconSize: AppIcon.md,
              iconEnabledColor: AppColors.textMuted,
              style: AppText.label(
                AppColors.textPrimary,
                weight: AppText.semibold,
              ),
              items: [
                for (final entry in options.entries)
                  DropdownMenuItem<T>(
                    value: entry.key,
                    child: Text(entry.value),
                  ),
              ],
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
