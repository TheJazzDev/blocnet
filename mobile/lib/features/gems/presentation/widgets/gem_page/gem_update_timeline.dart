import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/gems/presentation/widgets/parts/gems_tone.dart';
import 'package:blocnet/features/hunter/domain/hub_format.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/gem_page/gem_notice_cards.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_styles.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/feed_card/feed_deadline_line.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';

/// A gem's updates, newest first, on a 1px rail. The newest node carries the
/// accent; a quiet gem's silence sits on top as a gap.
class GemUpdateTimeline extends StatelessWidget {
  const GemUpdateTimeline({
    super.key,
    required this.updates,
    required this.now,
    required this.onOpen,
    this.gapDays,
  });

  /// Newest first.
  final List<Update> updates;
  final DateTime now;
  final ValueChanged<Update> onOpen;

  /// Days of silence to draw on top, or null.
  final int? gapDays;

  static const double _gutter = 20;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned(
          left: 5,
          top: 6,
          bottom: 20,
          child: SizedBox(
            width: 1,
            child: ColoredBox(color: AppColors.borderSubtle),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (gapDays != null)
              Padding(
                padding: const EdgeInsets.only(left: _gutter),
                child:
                    GemGapCard(key: const ValueKey('gem-gap'), days: gapDays!),
              ),
            for (var i = 0; i < updates.length; i++)
              _Event(
                key: ValueKey('timeline-${updates[i].id}'),
                update: updates[i],
                newest: i == 0,
                now: now,
                onTap: () => onOpen(updates[i]),
              ),
          ],
        ),
      ],
    );
  }
}

class _Event extends StatelessWidget {
  const _Event({
    super.key,
    required this.update,
    required this.newest,
    required this.now,
    required this.onTap,
  });

  final Update update;
  final bool newest;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final deadline = update.deadlineAt;
    final stats = [
      counted(update.likesCount, 'like'),
      counted(update.commentsCount, 'comment'),
    ].join(' · ');

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpace.xl),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: GemUpdateTimeline._gutter,
              child: Align(
                alignment: Alignment.topLeft,
                child: Container(
                  margin: const EdgeInsets.only(top: 3),
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.bgBase,
                    border: Border.all(
                      color: newest ? GemsTone.accent : AppColors.borderMuted,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${dayMonth(update.createdAt)} · '
                                '${shortAgo(update.createdAt, now)}'
                            .toUpperCase(),
                        style: HubType.caps(
                          AppColors.textFaint,
                          weight: AppText.semibold,
                        ),
                      ),
                      const Spacer(),
                      AppPill.caps(
                        label: update.priority.label,
                        color: update.priority.color,
                      ),
                    ],
                  ),
                  AppSpace.gapXs,
                  Text(
                    update.title,
                    style: HubType.body(
                      AppColors.textPrimary,
                      weight: AppText.semibold,
                    ),
                  ),
                  if (deadline != null)
                    FeedDeadlineLine(deadlineAt: deadline, now: now),
                  const SizedBox(height: AppSpace.hair),
                  Text(stats, style: HubType.meta(AppColors.textFaint)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
