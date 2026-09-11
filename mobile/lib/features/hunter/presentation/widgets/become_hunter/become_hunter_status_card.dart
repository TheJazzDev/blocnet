import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:flutter/material.dart';

enum _StatusTone { warning, success, error }

/// States of the Become-a-Hunter flow that are not the form itself:
/// pending review, approved (role still propagating), not approved (the
/// form is shown again beneath it), or the role already granted.
class BecomeHunterStatusCard extends StatelessWidget {
  const BecomeHunterStatusCard.pending({super.key})
      : _icon = Icons.hourglass_top_rounded,
        _title = 'Application pending',
        _body = 'Your application is with the Blocnet team. We review '
            'applications within a few days and will notify you as soon '
            'as a decision is made.',
        _tone = _StatusTone.warning,
        _actionLabel = null,
        _onAction = null;

  const BecomeHunterStatusCard.approved({super.key})
      : _icon = Icons.task_alt_rounded,
        _title = 'Application approved',
        _body = 'Welcome aboard. Hunter tools appear as soon as the role '
            'reaches your account, usually within a minute. Pull to refresh '
            'or reopen the app if it takes longer.',
        _tone = _StatusTone.success,
        _actionLabel = null,
        _onAction = null;

  const BecomeHunterStatusCard.rejected({super.key})
      : _icon = Icons.info_outline_rounded,
        _title = 'Application not approved',
        _body = 'Your last application was not approved this time. You can '
            'update your reasons below and apply again.',
        _tone = _StatusTone.error,
        _actionLabel = null,
        _onAction = null;

  const BecomeHunterStatusCard.alreadyHunter({
    super.key,
    required VoidCallback onOpenHunterSpace,
  })  : _icon = Icons.verified_rounded,
        _title = 'You are a Hunter',
        _body = 'Hunter tools live in the Hunter space: post Updates, '
            'submit Gems and track your stats and tips from Hunter Hub.',
        _tone = _StatusTone.success,
        _actionLabel = 'Open Hunter space',
        _onAction = onOpenHunterSpace;

  final IconData _icon;
  final String _title;
  final String _body;
  final _StatusTone _tone;
  final String? _actionLabel;
  final VoidCallback? _onAction;

  @override
  Widget build(BuildContext context) {
    final accent = switch (_tone) {
      _StatusTone.warning => AppColors.warning500,
      _StatusTone.success => AppColors.successColor,
      _StatusTone.error => AppColors.error500,
    };

    return Container(
      width: double.infinity,
      padding: AppSpace.card,
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadius.lg,
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: AppIcon.xl,
                height: AppIcon.xl,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: AppRadius.md,
                ),
                child: Icon(_icon, size: AppIcon.md, color: accent),
              ),
              AppSpace.wGapMd,
              Expanded(
                child: Text(
                  _title,
                  style: AppTypography.custom(
                    color: AppColors.textPrimary,
                    size: AppText.bodySize,
                    weight: AppText.bold,
                  ),
                ),
              ),
            ],
          ),
          AppSpace.gapMd,
          Text(
            _body,
            style: AppTypography.custom(
              color: AppColors.textMuted,
              size: AppText.bodySize,
              weight: AppText.regular,
              height: 1.5,
            ),
          ),
          if (_actionLabel != null) ...[
            AppSpace.gapLg,
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary500,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.md,
                  ),
                ),
                child: Text(
                  _actionLabel,
                  style: AppTypography.custom(
                    size: AppText.labelSize,
                    weight: AppText.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
