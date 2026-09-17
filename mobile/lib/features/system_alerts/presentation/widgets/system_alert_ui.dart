import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';

/// Flat card: surface ground, 1px subtle edge, [AppRadius.md].
BoxDecoration alertCardDecoration() => BoxDecoration(
      color: AppColors.bgSurface,
      borderRadius: AppRadius.md,
      border: Border.all(color: AppColors.borderSubtle),
    );

/// 10px bold caps in [color].
TextStyle alertCaps(Color color) =>
    AppText.caption(color, weight: AppText.bold).copyWith(letterSpacing: 1.0);

/// A left-aligned card with an icon, a title, a line and an optional action.
class AlertMessageCard extends StatelessWidget {
  const AlertMessageCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppSpace.card,
      decoration: alertCardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIconSquare(
            icon: icon,
            color: AppColors.textFaint,
            bordered: true,
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                      AppText.body(AppColors.textPrimary, weight: AppText.bold),
                ),
                const SizedBox(height: AppSpace.hair),
                Text(message, style: AppText.label(AppColors.textMuted)),
                if (action != null) ...[
                  const SizedBox(height: AppSpace.md),
                  action!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
