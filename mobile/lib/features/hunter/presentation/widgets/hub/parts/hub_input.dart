import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_styles.dart';
import 'package:flutter/material.dart';

/// A caps label over a Hub text input (elevated fill, accent focus).
class HubInput extends StatelessWidget {
  const HubInput({
    super.key,
    required this.label,
    required this.controller,
    required this.hint,
    this.fieldKey,
    this.onChanged,
    this.maxLength,
    this.maxLines = 1,
    this.enabled = true,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final Key? fieldKey;
  final ValueChanged<String>? onChanged;
  final int? maxLength;
  final int maxLines;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: AppRadius.md,
          borderSide: BorderSide(color: color),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: HubType.caps(AppColors.textFaint)),
        AppSpace.gapSm,
        TextField(
          key: fieldKey,
          controller: controller,
          onChanged: onChanged,
          enabled: enabled,
          maxLength: maxLength,
          maxLines: maxLines,
          minLines: 1,
          autocorrect: false,
          style: HubType.body(AppColors.textPrimary),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: HubType.body(AppColors.textFaint),
            counterStyle: AppText.caption(AppColors.textFaint),
            filled: true,
            fillColor: AppColors.bgElevated,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpace.md + 2,
              vertical: AppSpace.md,
            ),
            border: border(AppColors.borderMuted),
            enabledBorder: border(AppColors.borderMuted),
            disabledBorder: border(AppColors.borderSubtle),
            focusedBorder: border(HubTone.accent),
          ),
        ),
      ],
    );
  }
}
