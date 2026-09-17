import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/levels/presentation/widgets/level_badge.dart';
import 'package:blocnet/features/tips/data/models/tip_models.dart';
import 'package:blocnet/features/tips/presentation/models/tip_history_mode.dart';
import 'package:blocnet/shared/utils/get_timestamp.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';

/// One sent or received tip: who, where, when, and the amount. Meant to sit
/// in a bordered row group. [onTap] opens what the tip was for.
class TipHistoryListItem extends StatelessWidget {
  const TipHistoryListItem({
    super.key,
    required this.row,
    required this.mode,
    this.onTap,
  });

  final TipTransaction row;
  final TipHistoryMode mode;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isReceived = mode == TipHistoryMode.received;
    final code = row.currency.code.trim().isNotEmpty
        ? row.currency.code
        : row.currency.symbol;
    final counterparty = isReceived ? row.sender : row.recipient;
    final tint = isReceived ? AppColors.successColor : AppColors.primary400;
    final note = row.note?.trim() ?? '';
    final meta = [
      note.isNotEmpty ? note : tipContextLabel(row.contextType),
      getTimeStamp(row.createdAt),
    ].join(' · ');
    final nameStyle =
        AppText.body(AppColors.textPrimary, weight: AppText.semibold);

    final content = Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.lg, vertical: AppSpace.md),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.12),
              borderRadius: AppRadius.sm,
            ),
            child: Icon(
              isReceived ? Icons.south_west_rounded : Icons.north_east_rounded,
              size: AppIcon.sm,
              color: tint,
            ),
          ),
          AppSpace.wGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UserNameWithLevelIcon(
                  name: tipPartyLabel(counterparty, isReceived: isReceived),
                  currentLevel: counterparty.currentLevel,
                  levelBadgeSize: LevelBadgeSize.tiny,
                  iconSpacing: 4,
                  textStyle: nameStyle,
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
          AppSpace.wGapSm,
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isReceived
                    ? '+${row.amount} $code'
                    : '−${row.totalDebit} $code',
                style: AppText.body(
                  isReceived ? AppColors.successColor : AppColors.textPrimary,
                  weight: AppText.bold,
                ),
              ),
              if (!isReceived) ...[
                AppSpace.gapHair,
                Text(
                  'Fee ${row.fee}',
                  style: AppText.caption(AppColors.textFaint),
                ),
              ],
            ],
          ),
          if (onTap != null) ...[
            AppSpace.wGapXs,
            Icon(Icons.chevron_right_rounded,
                size: AppIcon.sm, color: AppColors.textFaint),
          ],
        ],
      ),
    );

    if (onTap == null) return content;
    return InkWell(onTap: onTap, child: content);
  }
}

/// The other party's name. Never a raw id.
String tipPartyLabel(TipUserPreview party, {required bool isReceived}) {
  final displayName = party.displayName?.trim();
  if (displayName != null && displayName.isNotEmpty) return displayName;
  final username = party.username?.trim();
  if (username != null && username.isNotEmpty) {
    return username.startsWith('@') ? username : '@$username';
  }
  return isReceived ? 'Member' : 'Hunter';
}

/// Where the tip was sent from, in two or three words.
String tipContextLabel(String? contextType) {
  switch (contextType?.trim()) {
    case 'update':
      return 'On an update';
    case 'public_profile':
      return 'From a profile';
    case null:
    case '':
      return 'Tip';
    default:
      final words = contextType!.trim().replaceAll('_', ' ').toLowerCase();
      return '${words[0].toUpperCase()}${words.substring(1)}';
  }
}
