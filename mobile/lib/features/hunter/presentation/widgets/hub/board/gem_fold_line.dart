import 'package:blocnet/app/theme.dart';
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.borderFaint)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              size: 16,
              color: AppColors.currentTick,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    HubType.body(AppColors.zincMuted, weight: FontWeight.w600),
              ),
            ),
            Icon(
              expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
              size: 16,
              color: AppColors.zincQuiet,
            ),
          ],
        ),
      ),
    );
  }
}
