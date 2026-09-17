import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/projects/data/models/priority_model.dart';
import 'package:blocnet/features/projects/data/models/secondary_tag_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/update/composer/composer_fields.dart';
import 'package:flutter/material.dart';

/// Low / Medium / High urgency.
class ComposerPriorityPicker extends StatelessWidget {
  const ComposerPriorityPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final Priority value;
  final ValueChanged<Priority> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<Priority>(
      value: value,
      decoration: composerFieldDecoration(),
      dropdownColor: AppColors.bgElevated,
      style: composerValueStyle(),
      items: [
        for (final priority in Priority.getAll())
          DropdownMenuItem<Priority>(
            value: priority,
            child: Text(
              '${priority.label} Urgency',
              style: AppTypography.custom(
                color: AppColors.textSecondary,
                size: AppText.labelSize,
                weight: FontWeight.w500,
              ),
            ),
          ),
      ],
      onChanged: (next) {
        if (next != null) onChanged(next);
      },
    );
  }
}

/// Secondary tags as outlined toggle pills.
class ComposerTagPicker extends StatelessWidget {
  const ComposerTagPicker({
    super.key,
    required this.tags,
    required this.selected,
    required this.onToggle,
  });

  final List<SecondaryTag> tags;
  final Set<String> selected;
  final void Function(String tagId, bool selected) onToggle;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) {
      return Text(
        'No tags yet',
        style: AppTypography.custom(
          color: AppColors.textFaint,
          size: AppText.labelSize,
          weight: FontWeight.w500,
        ),
      );
    }
    return Wrap(
      spacing: AppSpace.sm,
      runSpacing: AppSpace.sm,
      children: [
        for (final tag in tags)
          _TagToggle(
            label: tag.name,
            selected: selected.contains(tag.id),
            onTap: () => onToggle(tag.id, !selected.contains(tag.id)),
          ),
      ],
    );
  }
}

class _TagToggle extends StatelessWidget {
  const _TagToggle({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.primary500;
    final color = selected ? accent : AppColors.textMuted;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          constraints: const BoxConstraints(minHeight: 34),
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
          decoration: BoxDecoration(
            color: selected ? accent.withValues(alpha: 0.12) : null,
            borderRadius: AppRadius.full,
            border: Border.all(
              color: selected
                  ? accent.withValues(alpha: 0.4)
                  : AppColors.borderSubtle,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(Icons.check_rounded, size: AppIcon.xs, color: color),
                const SizedBox(width: AppSpace.xs),
              ],
              Flexible(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.custom(
                    color: color,
                    size: AppText.captionSize,
                    weight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The full-width filled button in the space accent, with a spinner while
/// sending.
class ComposerSubmitButton extends StatelessWidget {
  const ComposerSubmitButton({
    super.key,
    required this.label,
    required this.busy,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool busy;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.primary500;
    final onAccent =
        accent.computeLuminance() > 0.4 ? Colors.black : Colors.white;
    return Semantics(
      button: true,
      enabled: !busy,
      child: GestureDetector(
        onTap: busy ? null : onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 46,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: busy ? AppColors.bgElevated : accent,
            borderRadius: AppRadius.md,
          ),
          child: busy
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: accent,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: AppIcon.sm, color: onAccent),
                      const SizedBox(width: AppSpace.sm),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.custom(
                          color: onAccent,
                          size: AppText.bodySize,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
