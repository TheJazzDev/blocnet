import 'package:blocnet/features/badges/data/models/badge_models.dart';
import 'package:blocnet/features/quests/data/models/quest_models.dart';
import 'package:blocnet/features/quests/presentation/widgets/detail/quest_detail_footer.dart';
import 'package:blocnet/features/quests/presentation/widgets/detail/quest_detail_sections.dart';
import 'package:blocnet/features/quests/presentation/widgets/detail/quest_proof_section.dart';
import 'package:blocnet/features/quests/presentation/widgets/quest_card.dart';
import 'package:blocnet/features/quests/presentation/widgets/quest_pills.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

QuestModel _quest({
  String title = 'Follow Blocnet on X',
  int reward = 50,
  String? badgeId,
  String verification = 'auto',
}) {
  return QuestModel(
    id: 'q1',
    slug: 'follow-on-x',
    title: title,
    description: 'Follow the official account and come back to verify it. '
        'This description is long enough to need two lines on a phone.',
    type: QuestType.socialMedia,
    category: BadgeCategory.engagement,
    rewardPoints: reward,
    rewardBadgeId: badgeId,
    verificationMethod: verification,
    requiredProof: 'A screenshot of your profile following @blocnet_app',
    isActive: true,
    sortOrder: 1,
    createdAt: DateTime(2026),
  );
}

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _pump(WidgetTester tester, List<Widget> children) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('quest card fits at 375px with a long title and huge reward',
      (tester) async {
    _phone(tester);
    var taps = 0;
    final quest = _quest(
      title: 'Invite five friends who each complete their first mining '
          'cycle and post in the community before the season ends',
      reward: 1234567890,
    );
    await _pump(tester, [
      QuestCard(
        quest: quest,
        status: QuestStatus.notStarted,
        onTap: () => taps++,
      ),
      QuestCard(
        quest: quest,
        status: QuestStatus.pendingVerification,
      ),
      QuestCard(
        quest: quest,
        status: QuestStatus.completed,
        completedAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ]);

    expect(tester.takeException(), isNull);
    expect(find.text('1234567890 BNP'), findsNWidgets(3));
    expect(find.text('ENGAGEMENT'), findsNWidgets(3));
    // A new quest carries no status pill; the others say where they stand.
    expect(find.text('NEW'), findsNothing);
    expect(find.text('IN REVIEW'), findsOneWidget);
    expect(find.text('DONE'), findsOneWidget);
    expect(find.text('3 days ago'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsNWidgets(2));

    await tester.tap(find.byType(QuestCard).first);
    expect(taps, 1);
  });

  testWidgets('quest detail blocks fit at 375px', (tester) async {
    _phone(tester);
    final quest = _quest(
      title: 'A very long quest title that needs to wrap over two lines',
      reward: 987654321,
      badgeId: 'badge-1',
      verification: 'manual',
    );
    await _pump(tester, [
      QuestDetailHeader(quest: quest, status: QuestStatus.inProgress),
      QuestRewardSection(quest: quest),
      QuestAboutSection(quest: quest),
      QuestLinkSection(
        url: 'https://x.com/blocnet_app/status/1234567890123456789/very/long',
        buttonLabel: 'Open X',
        onOpen: () {},
      ),
      QuestProofForm(
        screenshot: null,
        noteController: TextEditingController(),
        isSubmitting: false,
        onPick: () {},
        onClearScreenshot: () {},
        onSubmit: () {},
      ),
      const QuestProofPending(),
      QuestCompletedCard(completedAt: DateTime.now()),
    ]);

    expect(tester.takeException(), isNull);
    expect(find.text('987654321 BNP'), findsOneWidget);
    expect(find.text('Included'), findsOneWidget);
    expect(find.text('Checked by a moderator'), findsOneWidget);
    expect(find.text('IN PROGRESS'), findsOneWidget);
    expect(find.text('Reward added · today'), findsOneWidget);
  });

  test('quest ages read short', () {
    final now = DateTime(2026, 9, 17);
    expect(formatQuestAge(now, now: now), 'today');
    expect(formatQuestAge(DateTime(2026, 9, 16), now: now), 'yesterday');
    expect(formatQuestAge(DateTime(2026, 9, 3), now: now), '2w ago');
    expect(formatQuestAge(DateTime(2026, 6, 1), now: now), '3mo ago');
  });
}
