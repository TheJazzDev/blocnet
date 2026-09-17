import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/gems/presentation/widgets/parts/gems_button.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_styles.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/home_panel.dart';
import 'package:flutter/material.dart';

/// An empty or failed state: a flat panel with an icon, a title, one short
/// line and, where there is one, the next step.
class GemsNotice extends StatelessWidget {
  const GemsNotice({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return HomePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: AppIcon.md, color: AppColors.textMuted),
              AppSpace.wGapSm,
              Expanded(
                child:
                    Text(title, style: HubType.rowTitle(AppColors.textPrimary)),
              ),
            ],
          ),
          if (message != null) ...[
            AppSpace.gapSm,
            Text(message!, style: HubType.body(AppColors.textMuted)),
          ],
          if (actionLabel != null && onAction != null) ...[
            AppSpace.gapLg,
            GemsButton(
              label: actionLabel!,
              onTap: onAction,
              small: true,
            ),
          ],
        ],
      ),
    );
  }
}

/// The spinner a view shows before its first data.
class GemsLoading extends StatelessWidget {
  const GemsLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xxxl),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary500,
          ),
        ),
      ),
    );
  }
}
