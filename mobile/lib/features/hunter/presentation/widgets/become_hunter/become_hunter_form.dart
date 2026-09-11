import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/services/users/hunter_application_store.dart';
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

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: ok ? AppColors.successColor : AppColors.error500,
          content: Text(
            ok
                ? 'Application sent. We will notify you once it is reviewed.'
                : (store.lastError ?? 'Could not send your application.'),
            style: AppTypography.custom(
              color: Colors.white,
              size: 12,
              weight: FontWeight.w600,
            ),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<HunterApplicationStore>();
    final error = _validationError ?? store.lastError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WHAT WE LOOK FOR',
          style: AppTypography.custom(
            color: AppColors.textFaint,
            size: 10,
            weight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        const _Criterion(
          icon: Icons.search_rounded,
          text: 'You research projects before you post about them.',
        ),
        const _Criterion(
          icon: Icons.forum_outlined,
          text: 'You are active in the community and your comments add signal.',
        ),
        const _Criterion(
          icon: Icons.schedule_rounded,
          text: 'You can post Updates consistently for the Gems you track.',
        ),
        const SizedBox(height: 22),
        Text(
          'WHY DO YOU WANT TO BE A HUNTER?',
          style: AppTypography.custom(
            color: AppColors.textFaint,
            size: 10,
            weight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _reason,
          maxLength: BecomeHunterForm.maxReasonLength,
          maxLines: 6,
          minLines: 4,
          enabled: !store.isSubmitting,
          textCapitalization: TextCapitalization.sentences,
          style: AppTypography.custom(
            size: 13,
            weight: FontWeight.w400,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText:
                'Which chains or sectors do you follow? Share past calls or research if you have any.',
            hintStyle: AppTypography.custom(
              size: 12,
              weight: FontWeight.w400,
              color: AppColors.textFaint,
            ),
            counterStyle: AppTypography.custom(
              size: 10,
              weight: FontWeight.w400,
              color: AppColors.textFaint,
            ),
            filled: true,
            fillColor: AppColors.bgSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.borderSubtle),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.borderSubtle),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary500),
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 6),
          Text(
            error,
            style: AppTypography.custom(
              size: 11,
              weight: FontWeight.w500,
              color: AppColors.error500,
            ),
          ),
        ],
        const SizedBox(height: 10),
        Text(
          'The Blocnet team reviews applications within a few days. You will '
          'get a notification either way.',
          style: AppTypography.custom(
            color: AppColors.textFaint,
            size: 11,
            weight: FontWeight.w400,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            onPressed: store.isSubmitting ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary500,
              disabledBackgroundColor: AppColors.bgElevated,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: store.isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : Text(
                    'Apply to become a Hunter',
                    style: AppTypography.custom(
                      size: 13,
                      color: Colors.black,
                      weight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _Criterion extends StatelessWidget {
  const _Criterion({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.primary400),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTypography.custom(
                color: AppColors.textSecondary,
                size: 12,
                weight: FontWeight.w400,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
