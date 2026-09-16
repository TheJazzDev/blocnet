import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/hunter/data/models/hunter_board_model.dart';
import 'package:blocnet/features/hunter/domain/hub_format.dart';
import 'package:blocnet/features/hunter/domain/hub_layout.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/board/gem_attention_parts.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/gem_header_line.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_button.dart';
import 'package:flutter/material.dart';

/// A gem that needs its hunter: due, quiet, or never updated.
///
/// The escalation is in mass and warmth. Due gains an amber edge; quiet an
/// orange edge and a warmed ground, and is the only row that carries actions
/// (D2). A never-updated gem has the due physique and one action, its first
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
        decoration: BoxDecoration(
          gradient: isQuiet
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.quietTop, AppColors.quietBottom],
                )
              : null,
          border: const Border(
            bottom: BorderSide(color: AppColors.borderFaint),
          ),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GemHeaderLine(gem: gem),
                  const SizedBox(height: 10),
                  if (kind == GemRowKind.neverUpdated)
                    GemNeverUpdatedLine(
                      listed: daysAgoSince(gem.listedAt, now),
                    )
                  else
                    GemLastLine(
                      title: gem.lastUpdate?.title ?? '',
                      ago: compact
                          ? daysAgo(gem.daysQuiet)
                          : 'last update ${daysAgo(gem.daysQuiet)}',
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
                      padding: const EdgeInsets.only(top: 12),
                      child: SizedBox(
                        width: double.infinity,
                        child: HubButton(
                          label: 'Post the first update',
                          icon: Icons.edit_outlined,
                          onTap: onPost,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 3,
                color: isQuiet ? AppColors.quietOrange : AppColors.dueEdge,
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
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Expanded(
            child: HubButton(
              label: 'Post update',
              icon: Icons.edit_outlined,
              onTap: onPost,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: HubButton(
              label: 'Open gem',
              tone: HubButtonTone.outline,
              onTap: onOpen,
            ),
          ),
        ],
      ),
    );
  }
}
