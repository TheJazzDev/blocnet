import 'package:flutter/material.dart';

/// One FAQ entry. Static copy; the FAQ screen renders the list below.
class FaqEntry {
  const FaqEntry({
    required this.question,
    required this.answer,
    required this.icon,
  });

  final String question;
  final String answer;
  final IconData icon;
}

const List<FaqEntry> faqEntries = [
  FaqEntry(
    icon: Icons.diamond_outlined,
    question: 'What is a Gem?',
    answer: 'A Gem is a crypto project listed on Blocnet. You find Gems in the '
        'Discover tab, follow the ones you care about and their Updates show '
        'up in your Home feed. Gems are proposed by Hunters and approved by '
        'the Blocnet team before they are listed.',
  ),
  FaqEntry(
    icon: Icons.radar_rounded,
    question: 'Who are Hunters?',
    answer:
        'Hunters are vetted members who track Gems, post Updates about them '
        'and submit new Gems for listing. Every Hunter has a public track '
        'record (success rate, sentiment, posting cadence) so you can judge '
        'their calls. You can tip a Hunter for a good call, and you can apply '
        'to become one from Profile > Become a Hunter.',
  ),
  FaqEntry(
    icon: Icons.bolt_rounded,
    question: 'What is an Update?',
    answer: 'An Update is a post by a Hunter about one Gem: news, on-chain '
        'activity, partnerships, airdrops or warnings. Each Update carries a '
        'priority (High, Medium or Low) and tags, and you can like, comment, '
        'bookmark, share and tip from it. Filter the Home feed by priority '
        'with the chips under the tabs.',
  ),
  FaqEntry(
    icon: Icons.track_changes_rounded,
    question: 'What is Alpha Radar?',
    answer:
        'Alpha Radar is the strip at the top of Home. It summarises which of '
        'the Gems you follow are most active right now, so you can see where '
        'attention is moving before you scroll the feed. It needs a few '
        'followed Gems to have anything to show.',
  ),
  FaqEntry(
    icon: Icons.insights_rounded,
    question: 'What is an Edge brief?',
    answer: 'Edge is Blocnet\'s decision engine. It reads the Updates from the '
        'Gems you follow, scores them and turns the result into short briefs: '
        'what changed, how urgent it is and why. Open the Edge page from Home '
        'to read the latest briefs. Follow a few Gems first, otherwise Edge '
        'has nothing to score.',
  ),
  FaqEntry(
    icon: Icons.memory_rounded,
    question: 'How does mining work?',
    answer: 'Open the Mining tab and start a session. BNP accrues every hour '
        'while the session runs; when the cycle ends you claim what you '
        'mined and start the next one. Binding a referral code and inviting '
        'friends boosts your rate, and the leaderboard shows the top miners.',
  ),
  FaqEntry(
    icon: Icons.toll_rounded,
    question: 'What are BNP and BNT?',
    answer: 'BNP is the Blocnet Point: the unit you mine, earn from quests and '
        'use to tip Hunters today. BNT is the Blocnet Token, which launches '
        'on BNB Smart Chain. When BNT launches, your BNP converts to BNT. '
        'Until then the wallet shows pre-launch balances only.',
  ),
  FaqEntry(
    icon: Icons.task_alt_outlined,
    question: 'What are quests?',
    answer: 'Quests are small tasks (follow a Gem, leave a comment, invite a '
        'friend and so on) that pay a BNP reward. Some complete automatically '
        'and some are checked by the Blocnet team before the reward lands. '
        'Find them under Profile > Quests.',
  ),
  FaqEntry(
    icon: Icons.emoji_events_outlined,
    question: 'What are badges?',
    answer:
        'Badges are achievements you earn for milestones such as your first '
        'tip, a mining streak or a number of comments. Pick one as your '
        'primary badge and it is shown next to your name across the app.',
  ),
  FaqEntry(
    icon: Icons.stairs_outlined,
    question: 'How do levels work?',
    answer: 'There are 15 levels grouped into five tiers. Each level lists its '
        'requirements: BNP earned, comments, days active, quests completed '
        'and, higher up, Updates published and Gems created. Profile > Levels '
        'shows every requirement with your current progress, and your level '
        'badge appears beside your username.',
  ),
  FaqEntry(
    icon: Icons.swap_horiz_rounded,
    question: 'What is a Space?',
    answer:
        'A Space is a view of the app for one of your roles. Everyone has the '
        'User space; Hunters also get the Hunter space (Hunter Hub, posting '
        'tools) and moderators get the Moderation space. Switch with the chip '
        'in the top-right corner. Your profile, badges, quests and levels are '
        'the same in every space.',
  ),
  FaqEntry(
    icon: Icons.volunteer_activism_outlined,
    question: 'How do tips work?',
    answer:
        'Tap Tip on an Update or on a Hunter\'s profile and choose an amount '
        'in BNP. The Hunter receives it minus a small platform fee. Your sent '
        'tips are listed under Profile > Tip History; Hunters see received '
        'tips in Hunter Hub.',
  ),
  FaqEntry(
    icon: Icons.support_agent_outlined,
    question: 'How do I get help?',
    answer: 'Email support@blocnet.app from the Help & Support screen. Include '
        'your username and, if it is about a specific Gem or Update, a link '
        'to it.',
  ),
];
