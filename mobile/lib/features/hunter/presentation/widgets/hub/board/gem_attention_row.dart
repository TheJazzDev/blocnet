import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/hunter/data/models/hunter_board_model.dart';
import 'package:blocnet/features/hunter/domain/hub_format.dart';
import 'package:blocnet/features/hunter/domain/hub_layout.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/board/gem_attention_parts.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/gem_header_line.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_styles.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';

/// A gem that needs its hunter: due, quiet, or never updated.
///
/// A flat list row under a hairline, like the old feed. The state reads from
/// the `DUE` / `QUIET` pill and the coloured age; quiet is the only row that
/// carries actions (D2). A never-updated gem has one action, its first
/// update. Waiting and reports render only when non-zero.
class GemAttentionRow extends StatelessWidget {
  const GemAttentionRow({
    super.key,
    required this.gem,
    required this.now,
    required this.compact,
    required this.onOpen,
    required this.onPost,
  });

  final HunterBoardGem gem;
  final DateTime now;

  /// D3: the shorter copy used while the current gems are folded.
  final bool compact;
  final VoidCallback onOpen;
  final VoidCallback onPost;

  @override
  Widget build(BuildContext context) {
    final kind = gem.rowKind;
    final isQuiet = kind == GemRowKind.quiet;
    final deadline = gem.nextDeadlineAt;
    final showDeadline = deadline != null && deadline.isAfter(now);

    return InkWell(
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: HubInsets.gutter,
          vertical: AppSpace.lg,
        ),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GemHeaderLine(gem: gem),
            AppSpace.gapMd,
            if (kind == GemRowKind.neverUpdated)
              GemNeverUpdatedLine(listed: daysAgoSince(gem.listedAt, now))
            else
              GemLastLine(
                title: gem.lastUpdate?.title ?? '',
                ago: compact
                    ? daysAgo(gem.daysQuiet)
                    : 'last update ${daysAgo(gem.daysQuiet)}',
                agoColor: isQuiet ? HubTone.quiet : HubTone.due,
              ),
            if (showDeadline) GemDeadlineLine(at: deadline, now: now),
            if (gem.membersWaiting > 0 || gem.openReports > 0)
              GemWaitMeta(
                waiting: gem.membersWaiting,
                reports: gem.openReports,
                compact: compact,
              ),
            if (isQuiet)
              _Actions(onPost: onPost, onOpen: onOpen)
            else if (kind == GemRowKind.neverUpdated)
              Padding(
                padding: const EdgeInsets.only(top: AppSpace.md),
                child: SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: 'Post the first update',
                    icon: Icons.edit_outlined,
                    onPressed: onPost,
                    color: HubTone.accent,
                    size: AppButtonSize.compact,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.onPost, required this.onOpen});

  final VoidCallback onPost;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.md),
      child: Row(
        children: [
          Expanded(
            child: AppButton(
              label: 'Post update',
              icon: Icons.edit_outlined,
              onPressed: onPost,
              color: HubTone.accent,
              size: AppButtonSize.compact,
            ),
          ),
          AppSpace.wGapSm,
          Expanded(
            child: AppButton(
              label: 'Open gem',
              variant: AppButtonVariant.outline,
              onPressed: onOpen,
              size: AppButtonSize.compact,
            ),
          ),
        ],
      ),
    );
  }
}
