import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/moderation/data/models/inactive_gem_model.dart';
import 'package:blocnet/features/moderation/presentation/widgets/common/mod_dialog.dart';
import 'package:blocnet/features/moderation/presentation/widgets/common/mod_parts.dart';
import 'package:blocnet/features/moderation/presentation/widgets/common/mod_styles.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';

/// What a moderator chose when resolving a quiet gem.
class InactiveGemResolution {
  const InactiveGemResolution({required this.outcome, required this.note});

  final InactiveGemOutcome outcome;
  final String note;
}

/// Asks for an outcome and a required note, and returns them, or null when
/// cancelled. The note is required because the audit log is the only record
/// of why reports on a gem were closed.
class ResolveInactiveGemDialog extends StatefulWidget {
  const ResolveInactiveGemDialog({required this.gemName, super.key});

  final String gemName;

  static const int minNoteLength = 3;
  static const int maxNoteLength = 500;

  static Future<InactiveGemResolution?> show(
    BuildContext context, {
    required String gemName,
  }) {
    return showDialog<InactiveGemResolution>(
      context: context,
      builder: (_) => ResolveInactiveGemDialog(gemName: gemName),
    );
  }

  @override
  State<ResolveInactiveGemDialog> createState() =>
      _ResolveInactiveGemDialogState();
}

class _ResolveInactiveGemDialogState extends State<ResolveInactiveGemDialog> {
  final TextEditingController _noteController = TextEditingController();
  InactiveGemOutcome? _outcome;

  bool get _canSubmit =>
      _outcome != null &&
      _noteController.text.trim().length >=
          ResolveInactiveGemDialog.minNoteLength;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ModDialog(
      title: 'Resolve ${widget.gemName}',
      confirmLabel: 'Resolve',
      onConfirm: _canSubmit
          ? () => Navigator.of(context).pop(
                InactiveGemResolution(
                  outcome: _outcome!,
                  note: _noteController.text.trim(),
                ),
              )
          : null,
      children: [
        const ModFieldLabel('Outcome'),
        Container(
          decoration: BoxDecoration(
            color: AppColors.bgBase,
            borderRadius: AppRadius.md,
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            children: [
              for (final outcome in InactiveGemOutcome.values) ...[
                if (outcome.index > 0) const AppHairline(),
                _OutcomeOption(
                  outcome: outcome,
                  selected: _outcome == outcome,
                  onTap: () => setState(() => _outcome = outcome),
                ),
              ],
            ],
          ),
        ),
        AppSpace.gapLg,
        const ModFieldLabel('Note'),
        TextField(
          controller: _noteController,
          minLines: 2,
          maxLines: 3,
          maxLength: ResolveInactiveGemDialog.maxNoteLength,
          onChanged: (_) => setState(() {}),
          style: AppText.body(AppColors.textPrimary),
          decoration: modInputDecoration(hint: 'What did you do, and why?'),
        ),
        Text(
          'Closes every open report on this gem. Reassigning is done in the '
          'console.',
          style: ModText.meta(AppColors.textMuted),
        ),
      ],
    );
  }
}

class _OutcomeOption extends StatelessWidget {
  const _OutcomeOption({
    required this.outcome,
    required this.selected,
    required this.onTap,
  });

  final InactiveGemOutcome outcome;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    outcome.label,
                    style: AppText.label(
                      selected ? AppColors.textPrimary : AppColors.textSecondary,
                      weight: selected ? AppText.bold : AppText.medium,
                    ),
                  ),
                ),
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: AppIcon.md,
                  color: selected ? ModTone.accent : AppColors.textFaint,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
