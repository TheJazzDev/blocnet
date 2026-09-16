import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/gem_monogram.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_styles.dart';
import 'package:flutter/material.dart';

/// The shared shell of an invite or review card: 32px monogram, name, a
/// status pill, then the body. [highlighted] draws the cyan inset an invite
/// carries; a review sits on a neutral one.
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
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.hubCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlighted
              ? AppColors.chainIce.withValues(alpha: 0.18)
              : AppColors.hubTileEdge,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GemMonogram(name: name, tag: tag, size: GemMonogramSize.small),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: HubType.rowTitle(AppColors.textPrimary),
                ),
              ),
              const SizedBox(width: 8),
              pill,
            ],
          ),
          const SizedBox(height: 8),
          body,
          if (actions != null) ...[
            const SizedBox(height: 12),
            actions!,
          ],
        ],
      ),
    );
  }
}
