import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/hunter/presentation/widgets/become_hunter/become_hunter_criteria.dart';
import 'package:blocnet/services/users/hunter_application_store.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:blocnet/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Reason field + submit button for a hunter application.
class BecomeHunterForm extends StatefulWidget {
  const BecomeHunterForm({super.key});

  /// Backend `CreateAdminApplicationDto.reason` is capped at 2000 chars.
  static const int maxReasonLength = 2000;
  static const int minReasonLength = 20;

  @override
  State<BecomeHunterForm> createState() => _BecomeHunterFormState();
}

class _BecomeHunterFormState extends State<BecomeHunterForm> {
  final TextEditingController _reason = TextEditingController();
  String? _validationError;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _reason.text.trim();
    if (reason.length < BecomeHunterForm.minReasonLength) {
      setState(() {
        _validationError =
            'Tell us a little more (at least ${BecomeHunterForm.minReasonLength} characters).';
      });
      return;
    }
    setState(() => _validationError = null);

    final store = context.read<HunterApplicationStore>();
    final ok = await store.submit(reason);
    if (!mounted) return;

    if (ok) {
      AppSnackbar.showSuccess(
        context,
        'Application sent. You will get a notification once it is reviewed.',
      );
    } else {
      AppSnackbar.showError(
        context,
        store.lastError ?? 'Could not send your application.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<HunterApplicationStore>();
    final error = _validationError ?? store.lastError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Header('What we look for', Icons.checklist_rounded),
        const BecomeHunterCriteria(),
        AppSpace.gapXl,
        const _Header('Why do you want to be a Hunter?', Icons.edit_note_rounded),
        TextField(
          controller: _reason,
          maxLength: BecomeHunterForm.maxReasonLength,
          maxLines: 6,
          minLines: 4,
          enabled: !store.isSubmitting,
          textCapitalization: TextCapitalization.sentences,
          style: AppText.body(AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Which chains or sectors do you follow? Link past calls '
                'or research if you have any.',
            hintStyle: AppText.body(AppColors.textFaint),
            counterStyle: AppText.caption(AppColors.textFaint),
            filled: true,
            fillColor: AppColors.bgSurface,
            contentPadding: AppSpace.card,
            border: _border(AppColors.borderSubtle),
            enabledBorder: _border(AppColors.borderSubtle),
            disabledBorder: _border(AppColors.borderSubtle),
            focusedBorder: _border(AppColors.primary500),
          ),
        ),
        if (error != null) ...[
          AppSpace.gapXs,
          Text(error, style: AppText.label(AppColors.error500)),
        ],
        AppSpace.gapMd,
        Text(
          'Reviewed within a few days.',
          style: AppText.label(AppColors.textFaint, weight: AppText.regular),
        ),
        AppSpace.gapLg,
        AppButton(
          label: 'Apply to become a Hunter',
          onPressed: store.isSubmitting ? null : _submit,
          isLoading: store.isSubmitting,
          fullWidth: true,
        ),
      ],
    );
  }

  static OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: AppRadius.md,
        borderSide: BorderSide(color: color),
      );
}

/// A small caps section label with a faint icon.
class _Header extends StatelessWidget {
  const _Header(this.label, this.icon);

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppSectionHeader(
      title: label,
      icon: icon,
      padding: const EdgeInsets.only(bottom: AppSpace.md),
    );
  }
}
