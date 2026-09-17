import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/hunter/data/models/hunter_gem_detail_model.dart';
import 'package:blocnet/features/hunter/domain/hub_format.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/gem_page/gem_notice_cards.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_styles.dart';
import 'package:flutter/material.dart';

/// The hunter's own updates on the gem, newest first, on a 1px rail. The
/// newest node carries the accent. A quiet gem's silence is drawn at the top as a gap.
class GemTimeline extends StatelessWidget {
  const GemTimeline({
    super.key,
    required this.events,
    required this.gapDays,
    required this.onEdit,
  });

  final List<HunterGemEvent> events;

  /// Null unless the gem is quiet.
  final int? gapDays;
  final ValueChanged<HunterGemEvent> onEdit;

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
                child: GemGapCard(
                  key: const ValueKey('gem-gap'),
                  days: gapDays!,
                ),
              ),
            for (var i = 0; i < events.length; i++)
              _Event(
                key: ValueKey('gem-event-${events[i].id}'),
                event: events[i],
                newest: i == 0,
                onEdit: () => onEdit(events[i]),
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
    required this.event,
    required this.newest,
    required this.onEdit,
  });

  final HunterGemEvent event;
  final bool newest;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final tips = formatTips(
      event.tipsAtomic,
      event.tipsCurrencyCode,
      event.tipsCurrencyDecimals,
    );
    final stats = [
      counted(event.likesCount, 'like'),
      counted(event.commentsCount, 'comment'),
      if (tips != null) '$tips tipped',
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: GemTimeline._gutter,
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
                    color: newest ? HubTone.accent : AppColors.borderMuted,
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
                    Expanded(
                      child: Text(
                        '${dayMonth(event.createdAt)} · '
                                '${urgencyLabel(event.priority)}'
                            .toUpperCase(),
                        style: HubType.caps(AppColors.textFaint,
                            weight: AppText.semibold),
                      ),
                    ),
                    InkWell(
                      key: ValueKey('gem-edit-${event.id}'),
                      onTap: onEdit,
                      borderRadius: AppRadius.sm,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit_outlined,
                                size: AppIcon.xs, color: AppColors.textMuted),
                            AppSpace.wGapXs,
                            Text(
                              'Edit',
                              style: HubType.meta(AppColors.textMuted,
                                  weight: AppText.medium),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                AppSpace.gapXs,
                Text(
                  event.title,
                  style: HubType.body(AppColors.textPrimary,
                      weight: AppText.semibold),
                ),
                const SizedBox(height: AppSpace.hair),
                Text(stats, style: HubType.meta(AppColors.textFaint)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
