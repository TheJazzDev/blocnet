import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:flutter/material.dart';

/// Terminal states of the Become-a-Hunter flow: application pending, or
/// the role has already been granted.
class BecomeHunterStatusCard extends StatelessWidget {
  const BecomeHunterStatusCard.pending({super.key})
      : _icon = Icons.hourglass_top_rounded,
        _title = 'Application pending',
        _body = 'Your application is with the Blocnet team. We review '
            'applications within a few days and will notify you as soon '
            'as a decision is made.',
        _actionLabel = null,
        _onAction = null;

  const BecomeHunterStatusCard.alreadyHunter({
    super.key,
    required VoidCallback onOpenHunterSpace,
  })  : _icon = Icons.verified_rounded,
        _title = 'You are a Hunter',
        _body = 'Hunter tools live in the Hunter space: post Updates, '
            'submit Gems and track your stats and tips from Hunter Hub.',
        _actionLabel = 'Open Hunter space',
        _onAction = onOpenHunterSpace;

  final IconData _icon;
  final String _title;
  final String _body;
  final String? _actionLabel;
  final VoidCallback? _onAction;

  @override
  Widget build(BuildContext context) {
    final accent =
        _onAction == null ? AppColors.warning500 : AppColors.successColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.lgValue),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.mdValue),
                ),
                child: Icon(_icon, size: AppIcon.md, color: accent),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Text(
                  _title,
                  style: AppTypography.custom(
                    color: AppColors.textPrimary,
                    size: AppText.bodySize,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Text(
            _body,
            style: AppTypography.custom(
              color: AppColors.textMuted,
              size: AppText.bodySize,
              weight: FontWeight.w400,
              height: 1.5,
            ),
          ),
          if (_actionLabel != null) ...[
            const SizedBox(height: AppSpace.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary500,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.mdValue),
                  ),
                ),
                child: Text(
                  _actionLabel,
                  style: AppTypography.custom(
                    size: AppText.labelSize,
                    weight: FontWeight.w700,
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
