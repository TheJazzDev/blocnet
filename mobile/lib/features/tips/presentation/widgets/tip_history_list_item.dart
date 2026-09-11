import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/levels/presentation/widgets/level_badge.dart';
import 'package:blocnet/features/tips/data/models/tip_models.dart';
import 'package:blocnet/features/tips/presentation/models/tip_history_mode.dart';
import 'package:blocnet/shared/utils/get_timestamp.dart';
import 'package:blocnet/shared/widgets/user_name_with_level_icon.dart';
import 'package:flutter/material.dart';

/// One sent/received tip row in the tip history list.
class TipHistoryListItem extends StatelessWidget {
  const TipHistoryListItem({
    super.key,
    required this.row,
    required this.mode,
  });

  final TipTransaction row;
  final TipHistoryMode mode;

  @override
  Widget build(BuildContext context) {
    final isReceived = mode == TipHistoryMode.received;
    final symbol = row.currency.symbol.trim().isEmpty
        ? row.currency.code
        : row.currency.symbol;
    final counterparty = isReceived ? row.sender : row.recipient;
    final counterpartyLabel = _partyLabel(
      counterparty,
      fallback: isReceived ? 'User' : 'Hunter',
    );
    final note = row.note?.trim();
    final nameStyle = AppTypography.custom(
      color: AppColors.textPrimary,
      size: AppText.labelSize,
      weight: FontWeight.w700,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpace.md),
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.mdValue),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: isReceived
                  ? AppColors.successColor.withValues(alpha: 0.12)
                  : AppColors.error500.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.smValue),
            ),
            child: Icon(
              isReceived ? Icons.south_west_rounded : Icons.north_east_rounded,
              size: AppIcon.sm,
              color: isReceived ? AppColors.successColor : AppColors.error500,
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(isReceived ? 'From ' : 'To ', style: nameStyle),
                    Flexible(
                      child: UserNameWithLevelIcon(
                        name: counterpartyLabel,
                        currentLevel: counterparty.currentLevel,
                        levelBadgeSize: LevelBadgeSize.tiny,
                        iconSpacing: 4,
                        textStyle: nameStyle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  note != null && note.isNotEmpty
                      ? note
                      : _contextLabel(row.contextType, isReceived: isReceived),
                  style: AppTypography.custom(
                    color: AppColors.textFaint,
                    size: AppText.captionSize,
                    weight: FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpace.hair),
                Text(
                  getTimeStamp(row.createdAt),
                  style: AppTypography.custom(
                    color: AppColors.textFaint,
                    size: AppText.captionSize,
                    weight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isReceived
                    ? '+${row.amount} $symbol'
                    : '-${row.totalDebit} $symbol',
                style: AppTypography.custom(
                  color:
                      isReceived ? AppColors.successColor : AppColors.error500,
                  size: AppText.labelSize,
                  weight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                isReceived
                    ? 'Tip ${row.amount}'
                    : 'Tip ${row.amount} · Fee ${row.fee}',
                style: AppTypography.custom(
                  color: AppColors.textFaint,
                  size: AppText.captionSize,
                  weight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _partyLabel(TipUserPreview party, {required String fallback}) {
  final displayName = party.displayName?.trim();
  if (displayName != null && displayName.isNotEmpty) {
    return displayName;
  }

  final username = party.username?.trim();
  if (username != null && username.isNotEmpty) {
    return username.startsWith('@') ? username : '@$username';
  }

  return party.id.isNotEmpty ? party.id : fallback;
}

String _contextLabel(
  String? contextType, {
  required bool isReceived,
}) {
  final value = contextType?.trim() ?? '';
  if (value.isEmpty) {
    return isReceived ? 'Tip received' : 'Tip sent';
  }
  return value.replaceAll('_', ' ');
}
