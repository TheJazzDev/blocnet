import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/quests/presentation/widgets/quest_card.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';

/// One tab of the Quests page: a list of [QuestCard]s, or an empty state
/// that still scrolls so pull-to-refresh keeps working.
class QuestListTab extends StatelessWidget {
  const QuestListTab({
    super.key,
    required this.cards,
    required this.emptyIcon,
    required this.emptyTitle,
    this.emptyMessage,
  });

  final List<QuestCard> cards;
  final IconData emptyIcon;
  final String emptyTitle;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          AppEmptyState(
            icon: emptyIcon,
            title: emptyTitle,
            message: emptyMessage,
          ),
        ],
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: AppSpace.allLg,
      itemCount: cards.length,
      separatorBuilder: (_, __) => AppSpace.gapMd,
      itemBuilder: (_, index) => cards[index],
    );
  }
}
