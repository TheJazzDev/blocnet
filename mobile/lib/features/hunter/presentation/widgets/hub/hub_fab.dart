import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The Hub's extended pill: `✎ Post update`, or `+ Submit a gem` on day one.
class HubFab extends StatelessWidget {
  const HubFab({
    super.key,
    required this.dayOne,
    required this.onPostUpdate,
    required this.onSubmitGem,
  });

  final bool dayOne;
  final VoidCallback onPostUpdate;
  final VoidCallback onSubmitGem;

  @override
  Widget build(BuildContext context) {
    final label = dayOne ? 'Submit a gem' : 'Post update';
    return Semantics(
      button: true,
      child: GestureDetector(
        key: const ValueKey('hub-fab'),
        onTap: () {
          HapticFeedback.mediumImpact();
          (dayOne ? onSubmitGem : onPostUpdate)();
        },
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.hunterFill,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: AppColors.hunterFill.withValues(alpha: 0.7),
                blurRadius: 24,
                spreadRadius: -6,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                dayOne ? Icons.add_rounded : Icons.edit_outlined,
                size: 16,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTypography.custom(
                  size: 15,
                  weight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
