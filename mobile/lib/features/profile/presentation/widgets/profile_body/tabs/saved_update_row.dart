import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/shared/utils/get_timestamp.dart';
import 'package:flutter/material.dart';

/// One saved update: title, "gem · time", and a remove button.
class SavedUpdateRow extends StatelessWidget {
  const SavedUpdateRow({
    super.key,
    required this.update,
    required this.onOpen,
    required this.onRemove,
  });

  final Update update;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final gemName = update.project?.name.trim();
    final meta = [
      if (gemName != null && gemName.isNotEmpty) gemName,
      getTimeStamp(update.createdAt),
    ].join(' · ');

    return InkWell(
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.lg,
          AppSpace.sm,
          AppSpace.xs,
          AppSpace.sm,
        ),
        child: Row(
          children: [
            Icon(
              Icons.bookmark_rounded,
              size: AppIcon.sm,
              color: AppColors.primary400,
            ),
            AppSpace.wGapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    update.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(
                      AppColors.textPrimary,
                      weight: AppText.semibold,
                    ),
                  ),
                  AppSpace.gapHair,
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.label(AppColors.textMuted,
                        weight: AppText.regular),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Remove from saved',
              onPressed: onRemove,
              icon: Icon(
                Icons.bookmark_remove_outlined,
                size: AppIcon.md,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
