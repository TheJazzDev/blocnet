import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/mining/data/models/mining_models.dart';
import 'package:flutter/material.dart';
import 'package:blocnet/app/typography.dart';

class ReferralCodeCard extends StatelessWidget {
  const ReferralCodeCard({
    super.key,
    required this.snapshot,
    required this.onCopy,
    required this.onBind,
    required this.isBinding,
  });

  final MiningSnapshot? snapshot;
  final VoidCallback onCopy;
  final VoidCallback onBind;
  final bool isBinding;

  @override
  Widget build(BuildContext context) {
    final referral = snapshot?.referral;
    final isBound = referral?.isBound ?? false;
    final canBind = !isBound && (referral?.bindWindowOpen ?? false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'REFERRAL',
          style: AppTypography.custom(
            color: AppColors.textFaint,
            size: 11,
            weight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.bgSurface,
                AppColors.bgSurface.withValues(alpha: 0.82),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your code',
                            style: AppTypography.custom(
                              color: AppColors.textMuted,
                              size: 11,
                              weight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            referral?.code ?? '--------',
                            style: AppTypography.custom(
                              color: AppColors.textPrimary,
                              size: 20,
                              height: 1,
                              weight: FontWeight.w700,
                              letterSpacing: 1.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: onCopy,
                      icon: Icon(
                        Icons.copy_rounded,
                        color: AppColors.primary400,
                        size: 16,
                      ),
                      label: Text(
                        'Copy',
                        style: AppTypography.custom(
                          color: AppColors.primary400,
                          size: 12,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoChip(
                      label:
                          'Active direct referrals: ${referral?.activeDirectReferrals ?? 0}',
                    ),
                    _InfoChip(
                      label:
                          'Total referrals: ${referral?.totalDirectReferrals ?? 0}',
                    ),
                    if (isBound) const _InfoChip(label: 'Referrer locked'),
                  ],
                ),
                if (isBound && referral?.referredBy != null) ...[
                  const SizedBox(height: 10),
                  Builder(
                    builder: (context) {
                      final referrer = referral!.referredBy!;
                      final normalizedUsername =
                          referrer.username?.trim().replaceAll('@', '');
                      final referrerLabel =
                          (normalizedUsername != null &&
                                  normalizedUsername.isNotEmpty)
                              ? '@$normalizedUsername'
                              : 'linked referrer';
                      return Text(
                        'You are under $referrerLabel.',
                        style: AppTypography.custom(
                          color: AppColors.textSecondary,
                          size: 11,
                          weight: FontWeight.w500,
                        ),
                      );
                    },
                  ),
                ],
                if (canBind) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: isBinding ? null : onBind,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: AppColors.primary500.withValues(alpha: 0.45),
                        ),
                        foregroundColor: AppColors.primary400,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: isBinding
                          ? SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                color: AppColors.primary400,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(
                              Icons.link_rounded,
                              color: AppColors.primary400,
                              size: 16,
                            ),
                      label: Text(
                        'Bind Referrer Code',
                        style: AppTypography.custom(
                          color: AppColors.textPrimary,
                          weight: FontWeight.w700,
                          size: 12,
                        ),
                      ),
                    ),
                  ),
                ],
                if (!canBind && !isBound) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Referral bind window is closed for this account.',
                    style: AppTypography.custom(
                      color: AppColors.textFaint,
                      size: 11,
                      weight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTypography.custom(
          color: AppColors.textSecondary,
          size: 11,
          weight: FontWeight.w600,
        ),
      ),
    );
  }
}
