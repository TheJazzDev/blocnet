import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/gem_monogram.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_styles.dart';
import 'package:flutter/material.dart';

/// The shared shell of an invite or review card: 32px monogram, name, a
/// status pill, then the body, on a flat surface card. [highlighted] gives
/// an invite a faint accent border; a review keeps the neutral one.
class AnswerCardFrame extends StatelessWidget {
  const AnswerCardFrame({
    super.key,
    required this.name,
    required this.tag,
    required this.pill,
    required this.body,
    this.highlighted = false,
    this.actions,
  });

  final String name;
  final String tag;
  final Widget pill;
  final Widget body;
  final bool highlighted;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        HubInsets.gutter,
        0,
        HubInsets.gutter,
        AppSpace.md,
      ),
      padding: AppSpace.card,
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadius.md,
        border: Border.all(
          color: highlighted
              ? HubTone.accent.withValues(alpha: 0.3)
              : AppColors.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GemMonogram(name: name, tag: tag, size: GemMonogramSize.small),
              AppSpace.wGapMd,
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: HubType.rowTitle(AppColors.textPrimary),
                ),
              ),
              AppSpace.wGapSm,
              pill,
            ],
          ),
          AppSpace.gapMd,
          body,
          if (actions != null) ...[
            AppSpace.gapMd,
            actions!,
          ],
        ],
      ),
    );
  }
}
