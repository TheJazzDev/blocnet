import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/moderation/presentation/widgets/common/mod_dialog.dart';
import 'package:blocnet/features/moderation/presentation/widgets/common/mod_parts.dart';
import 'package:flutter/material.dart';

const int _minReason = 3;
const String _reasonTooShort = 'Write at least 3 characters.';

/// A duration and a reason, from [showModDurationDialog].
class ModDurationInput {
  const ModDurationInput({required this.hours, required this.reason});

  final int hours;
  final String reason;
}

/// Posting and/or commenting hours and a reason, from
/// [showModRestrictionDialog].
class ModRestrictionInput {
  const ModRestrictionInput({
    required this.postingHours,
    required this.commentingHours,
    required this.reason,
  });

  final int? postingHours;
  final int? commentingHours;
  final String reason;
}

/// Asks for a note. Returns the trimmed text, or null when cancelled.
Future<String?> showModReasonDialog(
  BuildContext context, {
  required String title,
  required String hint,
  required bool required,
  String confirmLabel = 'Continue',
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _ReasonDialog(
      title: title,
      hint: hint,
      required: required,
      confirmLabel: confirmLabel,
    ),
  );
}

Future<ModDurationInput?> showModDurationDialog(
  BuildContext context, {
  required String title,
  required String hint,
  int initialHours = 24,
}) {
  return showDialog<ModDurationInput>(
    context: context,
    builder: (_) => _DurationDialog(
      title: title,
      hint: hint,
      initialHours: initialHours,
    ),
  );
}

Future<ModRestrictionInput?> showModRestrictionDialog(BuildContext context) {
  return showDialog<ModRestrictionInput>(
    context: context,
    builder: (_) => const _RestrictionDialog(),
  );
}

// The dialogs own their controllers, so nothing is disposed while the
// closing animation still paints the fields.

class _ReasonDialog extends StatefulWidget {
  const _ReasonDialog({
    required this.title,
    required this.hint,
    required this.required,
    required this.confirmLabel,
  });

  final String title;
  final String hint;
  final bool required;
  final String confirmLabel;

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (widget.required && text.length < _minReason) {
      setState(() => _error = _reasonTooShort);
      return;
    }
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    return ModDialog(
      title: widget.title,
      confirmLabel: widget.confirmLabel,
      onConfirm: _submit,
      children: [
        ModFieldLabel(widget.required ? 'Reason' : 'Note (optional)'),
        _ReasonField(controller: _controller, hint: widget.hint),
        ModInlineError(_error),
      ],
    );
  }
}

class _DurationDialog extends StatefulWidget {
  const _DurationDialog({
    required this.title,
    required this.hint,
    required this.initialHours,
  });

  final String title;
  final String hint;
  final int initialHours;

  @override
  State<_DurationDialog> createState() => _DurationDialogState();
}

class _DurationDialogState extends State<_DurationDialog> {
  late final _hours = TextEditingController(text: '${widget.initialHours}');
  final _reason = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _hours.dispose();
    _reason.dispose();
    super.dispose();
  }

  void _submit() {
    final hours = int.tryParse(_hours.text.trim());
    final reason = _reason.text.trim();
    if (hours == null || hours <= 0) {
      setState(() => _error = 'Enter a duration above 0.');
      return;
    }
    if (reason.length < _minReason) {
      setState(() => _error = _reasonTooShort);
      return;
    }
    Navigator.of(context).pop(ModDurationInput(hours: hours, reason: reason));
  }

  @override
  Widget build(BuildContext context) {
    return ModDialog(
      title: widget.title,
      confirmLabel: 'Apply',
      onConfirm: _submit,
      children: [
        const ModFieldLabel('Hours'),
        _HoursField(controller: _hours),
        AppSpace.gapMd,
        const ModFieldLabel('Reason'),
        _ReasonField(controller: _reason, hint: widget.hint),
        ModInlineError(_error),
      ],
    );
  }
}

class _RestrictionDialog extends StatefulWidget {
  const _RestrictionDialog();

  @override
  State<_RestrictionDialog> createState() => _RestrictionDialogState();
}

class _RestrictionDialogState extends State<_RestrictionDialog> {
  final _posting = TextEditingController();
  final _commenting = TextEditingController();
  final _reason = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _posting.dispose();
    _commenting.dispose();
    _reason.dispose();
    super.dispose();
  }

  void _submit() {
    final posting = int.tryParse(_posting.text.trim());
    final commenting = int.tryParse(_commenting.text.trim());
    final reason = _reason.text.trim();
    final validPosting = posting != null && posting > 0;
    final validCommenting = commenting != null && commenting > 0;
    if (!validPosting && !validCommenting) {
      setState(() => _error = 'Enter posting or commenting hours above 0.');
      return;
    }
    if (reason.length < _minReason) {
      setState(() => _error = _reasonTooShort);
      return;
    }
    Navigator.of(context).pop(
      ModRestrictionInput(
        postingHours: validPosting ? posting : null,
        commentingHours: validCommenting ? commenting : null,
        reason: reason,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ModDialog(
      title: 'Restrict',
      confirmLabel: 'Apply',
      onConfirm: _submit,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ModFieldLabel('Posting hours'),
                  _HoursField(controller: _posting, hint: 'None'),
                ],
              ),
            ),
            AppSpace.wGapSm,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ModFieldLabel('Comment hours'),
                  _HoursField(controller: _commenting, hint: 'None'),
                ],
              ),
            ),
          ],
        ),
        AppSpace.gapMd,
        const ModFieldLabel('Reason'),
        _ReasonField(controller: _reason, hint: 'Why restrict this member?'),
        ModInlineError(_error),
      ],
    );
  }
}

class _ReasonField extends StatelessWidget {
  const _ReasonField({required this.controller, required this.hint});

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: 2,
      maxLines: 4,
      style: AppText.body(AppColors.textPrimary),
      decoration: modInputDecoration(hint: hint),
    );
  }
}

class _HoursField extends StatelessWidget {
  const _HoursField({required this.controller, this.hint});

  final TextEditingController controller;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: AppText.body(AppColors.textPrimary),
      decoration: modInputDecoration(hint: hint),
    );
  }
}
