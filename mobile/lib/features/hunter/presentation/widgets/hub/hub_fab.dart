import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The Hub's extended button: `✎ Post update`, or `+ Submit a gem` on day
/// one. Drawn like the old app's FAB — an accent tile with dark ink and a
/// soft accent glow.
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
          // 48px: the size of the + buttons' family, not Material's 56.
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
          decoration: BoxDecoration(
            color: HubTone.accent,
            borderRadius: AppRadius.lg,
            boxShadow: [
              BoxShadow(
                color: AppColors.cyanGlow,
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                dayOne ? Icons.add_rounded : Icons.edit_outlined,
                size: AppIcon.md,
                color: HubTone.onAccent,
              ),
              AppSpace.wGapSm,
              Text(
                label,
                style: AppText.body(HubTone.onAccent, weight: AppText.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
