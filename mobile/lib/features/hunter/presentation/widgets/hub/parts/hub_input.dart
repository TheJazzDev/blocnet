import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_styles.dart';
import 'package:flutter/material.dart';

/// A caps label over a Hub text input (radius 10, zinc-800 fill, cyan focus).
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
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: color),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: HubType.caps(AppColors.zincDim)),
        const SizedBox(height: 8),
        TextField(
          key: fieldKey,
          controller: controller,
          onChanged: onChanged,
          enabled: enabled,
          maxLength: maxLength,
          maxLines: maxLines,
          minLines: 1,
          autocorrect: false,
          style: HubType.body(AppColors.zincStrong),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: HubType.body(AppColors.zincDim),
            counterStyle: HubType.meta(AppColors.zincCaption),
            filled: true,
            fillColor: AppColors.bgElevated,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            border: border(AppColors.borderSubtle),
            enabledBorder: border(AppColors.borderSubtle),
            disabledBorder: border(AppColors.borderSubtle),
            focusedBorder: border(AppColors.hunterFill),
          ),
        ),
      ],
    );
  }
}
