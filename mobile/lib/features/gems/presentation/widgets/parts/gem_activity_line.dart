import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/hunter/domain/hub_format.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_styles.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:flutter/material.dart';

/// The newest update's title and when — `KYC opened · 2d ago` — or
/// `No updates yet`.
class GemActivityLine extends StatelessWidget {
  const GemActivityLine({
    super.key,
    required this.newest,
    required this.now,
  });

  final Update? newest;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final update = newest;
    if (update == null) {
      return Text(
        'No updates yet',
        style: HubType.meta(AppColors.textFaint),
      );
    }
    final title = update.title.trim().isEmpty
        ? update.description.trim()
        : update.title.trim();
    return Row(
      children: [
        Icon(Icons.bolt_rounded, size: AppIcon.xs, color: AppColors.primary500),
        AppSpace.wGapXs,
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: HubType.meta(AppColors.textSecondary, weight: AppText.medium),
          ),
        ),
        Text(
          ' · ${shortAgo(update.createdAt, now)}',
          maxLines: 1,
          style: HubType.meta(AppColors.textFaint),
        ),
      ],
    );
  }
}
