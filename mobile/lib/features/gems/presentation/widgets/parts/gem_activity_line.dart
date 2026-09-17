import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/gems/domain/gem_listing.dart';
import 'package:blocnet/features/hunter/domain/hub_format.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_styles.dart';
import 'package:flutter/material.dart';

/// The newest update's title and when — `KYC opened · 2d ago` — or
/// `Last update 19d ago` when that update is not loaded, or
/// `No updates yet`.
class GemActivityLine extends StatelessWidget {
  const GemActivityLine({super.key, required this.gem, required this.now});

  final GemListing gem;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final last = gem.lastUpdateAt;
    if (last == null) {
      return Text('No updates yet', style: HubType.meta(AppColors.textFaint));
    }
    if (!gem.newestIsLatest) {
      return Text(
        'Last update ${shortAgo(last, now)}',
        style: HubType.meta(AppColors.textSecondary, weight: AppText.medium),
      );
    }
    final update = gem.newest!;
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
            style:
                HubType.meta(AppColors.textSecondary, weight: AppText.medium),
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
