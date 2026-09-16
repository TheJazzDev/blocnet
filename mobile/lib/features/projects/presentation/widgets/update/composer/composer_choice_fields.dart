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

/// Secondary tags as toggle chips.
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
        'No secondary tags available',
        style: AppTypography.custom(
          color: AppColors.textFaint,
          size: AppText.bodySize,
          weight: FontWeight.w400,
        ),
      );
    }
    return Wrap(
      spacing: AppSpace.sm,
      runSpacing: AppSpace.sm,
      children: [
        for (final tag in tags)
          FilterChip(
            selected: selected.contains(tag.id),
            onSelected: (value) => onToggle(tag.id, value),
            label: Text(
              tag.name,
              style: AppTypography.custom(
                color: selected.contains(tag.id)
                    ? AppColors.teal400
                    : AppColors.textMuted,
                size: AppText.bodySize,
                weight: FontWeight.w400,
              ),
            ),
            selectedColor: AppColors.teal500.withValues(alpha: 0.15),
            backgroundColor: AppColors.bgElevated,
            side: BorderSide(
              color: selected.contains(tag.id)
                  ? AppColors.teal500
                  : AppColors.borderSubtle,
            ),
            showCheckmark: false,
          ),
      ],
    );
  }
}

/// The full-width submit button, with a spinner while sending.
class ComposerSubmitButton extends StatelessWidget {
  const ComposerSubmitButton({
    super.key,
    required this.label,
    required this.busy,
    required this.onTap,
  });

  final String label;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: busy ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: AppSpace.lg),
          decoration: BoxDecoration(
            gradient: busy
                ? null
                : LinearGradient(
                    colors: [AppColors.teal500, AppColors.primary500],
                  ),
            color: busy ? AppColors.bgElevated : null,
            borderRadius: BorderRadius.circular(AppRadius.lgValue),
          ),
          child: busy
              ? Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.teal400,
                    ),
                  ),
                )
              : Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppTypography.custom(
                    color: Colors.white,
                    size: AppText.bodySize,
                    weight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}
