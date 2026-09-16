import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/moderation/data/models/inactive_gem_model.dart';
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
    return AlertDialog(
      backgroundColor: AppColors.bgSurface,
      title: Text(
        'Resolve reports on ${widget.gemName}',
        style: AppTypography.custom(
          color: AppColors.textPrimary,
          size: AppText.bodySize,
          weight: FontWeight.w700,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('Outcome'),
            const SizedBox(height: AppSpace.sm),
            for (final outcome in InactiveGemOutcome.values)
              _OutcomeOption(
                outcome: outcome,
                selected: _outcome == outcome,
                onTap: () => setState(() => _outcome = outcome),
              ),
            const SizedBox(height: AppSpace.md),
            _label('Note (required)'),
            const SizedBox(height: AppSpace.sm),
            TextField(
              controller: _noteController,
              maxLines: 3,
              maxLength: ResolveInactiveGemDialog.maxNoteLength,
              onChanged: (_) => setState(() {}),
              style: AppTypography.custom(
                color: AppColors.textPrimary,
                size: AppText.bodySize,
                weight: FontWeight.w400,
              ),
              decoration: InputDecoration(
                hintText: 'What did you do, and why?',
                hintStyle: AppTypography.custom(
                  color: AppColors.textMuted,
                  size: AppText.bodySize,
                  weight: FontWeight.w400,
                ),
                filled: true,
                fillColor: AppColors.bgBase,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.smValue),
                  borderSide: const BorderSide(color: AppColors.borderSubtle),
                ),
                contentPadding: const EdgeInsets.all(AppSpace.md),
              ),
            ),
            Text(
              'Resolving closes every open report on this gem. It does not '
              'reassign the gem — that is decided in the console.',
              style: AppTypography.custom(
                color: AppColors.textMuted,
                size: AppText.captionSize,
                weight: FontWeight.w400,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: AppTypography.custom(
              color: AppColors.textMuted,
              size: AppText.labelSize,
              weight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _canSubmit
              ? () => Navigator.of(context).pop(
                    InactiveGemResolution(
                      outcome: _outcome!,
                      note: _noteController.text.trim(),
                    ),
                  )
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.moderationAccent,
            foregroundColor: Colors.white,
            disabledBackgroundColor:
                AppColors.moderationAccent.withValues(alpha: 0.3),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.lg, vertical: AppSpace.md),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.smValue),
            ),
          ),
          child: Text(
            'Resolve',
            style: AppTypography.custom(
              color: Colors.white,
              size: AppText.labelSize,
              weight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: AppTypography.custom(
        color: AppColors.textMuted,
        size: AppText.labelSize,
        weight: FontWeight.w600,
      ),
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
    final color = selected ? AppColors.moderationAccent : AppColors.textMuted;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.smValue),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: AppIcon.md,
              color: color,
            ),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: Text(
                outcome.label,
                style: AppTypography.custom(
                  color: selected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  size: AppText.labelSize,
                  weight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
