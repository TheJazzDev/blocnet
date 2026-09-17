import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_styles.dart';
import 'package:flutter/material.dart';

/// `✓ 9 current, all posted this week ⌄` — the current gems folded behind
/// one line that carries the proof. Tapping expands them.
class GemFoldLine extends StatelessWidget {
  const GemFoldLine({
    super.key,
    required this.label,
    required this.expanded,
    required this.onToggle,
  });

  final String label;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: HubInsets.gutter,
          vertical: AppSpace.lg,
        ),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle_rounded,
              size: AppIcon.sm,
              color: HubTone.current,
            ),
            AppSpace.wGapSm,
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: HubType.body(AppColors.textSecondary,
                    weight: AppText.medium),
              ),
            ),
            Icon(
              expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
              size: AppIcon.md,
              color: AppColors.textFaint,
            ),
          ],
        ),
      ),
    );
  }
}
