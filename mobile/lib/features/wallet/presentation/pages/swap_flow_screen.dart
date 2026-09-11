import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:flutter/material.dart';

/// Swap is not shipped yet. This screen is a single, honest "not available"
/// state with nothing tappable, so the Swap quick action never leads to a
/// list that goes nowhere.
class SwapFlowScreen extends StatelessWidget {
  const SwapFlowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        title: Text(
          'Swap',
          style: AppTypography.custom(
            color: AppColors.textPrimary,
            size: AppText.titleSize,
            weight: FontWeight.w700,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.xxl, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.teal500.withValues(alpha: 0.2),
                      AppColors.teal400.withValues(alpha: 0.05),
                    ],
                  ),
                ),
                child: Icon(
                  Icons.swap_horiz_rounded,
                  size: AppIcon.xl,
                  color: AppColors.teal400,
                ),
              ),
              const SizedBox(height: AppSpace.xl),
              Text(
                "Swap isn't available yet",
                style: AppTypography.custom(
                  color: AppColors.textPrimary,
                  size: AppText.titleSize,
                  weight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpace.md),
              Text(
                'In-app swaps arrive after BNT launches on BSC. '
                'Until then you can still receive and send your assets.',
                style: AppTypography.custom(
                  color: AppColors.textMuted,
                  size: AppText.bodySize,
                  weight: FontWeight.w400,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
