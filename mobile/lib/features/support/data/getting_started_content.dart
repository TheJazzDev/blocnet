import 'package:blocnet/constants/app_routes.dart';
import 'package:flutter/material.dart';

/// One step of the Getting Started guide. [route] is an optional
/// in-app destination for the step's action button.
class GettingStartedStep {
  const GettingStartedStep({
    required this.title,
    required this.body,
    required this.icon,
    this.actionLabel,
    this.route,
  });

  final String title;
  final String body;
  final IconData icon;
  final String? actionLabel;
  final String? route;
}

const List<GettingStartedStep> gettingStartedSteps = [
  GettingStartedStep(
    icon: Icons.diamond_outlined,
    title: 'Follow a few Gems',
    body:
        'Open the Discover tab, browse the curated feed or use the filters, '
        'and tap Follow on the Gems you want to track. Everything else on '
        'Blocnet (your feed, Alpha Radar, Edge briefs) starts from the Gems '
        'you follow.',
  ),
  GettingStartedStep(
    icon: Icons.home_outlined,
    title: 'Read your feed',
    body:
        'Home shows Updates from your Gems, posted by Hunters. Alpha Radar '
        'at the top tells you which Gems are moving; the Edge card turns the '
        'latest Updates into short briefs. Use the High / Medium / Low chips '
        'to focus on what matters.',
  ),
  GettingStartedStep(
    icon: Icons.memory_rounded,
    title: 'Start mining BNP',
    body:
        'In the Mining tab start a session and claim your BNP when the cycle '
        'ends. Bind a referral code once to boost your rate, and share your '
        'own code from Profile > Referral Code.',
    actionLabel: 'Open Mining',
    route: AppRoutes.mining,
  ),
  GettingStartedStep(
    icon: Icons.task_alt_outlined,
    title: 'Complete quests and level up',
    body:
        'Quests pay BNP for simple actions. Badges mark your milestones and '
        'your level grows with BNP earned, comments, active days and quests. '
        'Check the Levels page to see exactly what the next level needs.',
    actionLabel: 'See quests',
    route: AppRoutes.quests,
  ),
  GettingStartedStep(
    icon: Icons.forum_outlined,
    title: 'Join the community',
    body:
        'The Community tab has General and Market Talk discussions. Comment '
        'on Updates and posts, mention people with @, and report anything '
        'that breaks the rules.',
  ),
  GettingStartedStep(
    icon: Icons.volunteer_activism_outlined,
    title: 'Tip Hunters, or become one',
    body:
        'When a Hunter\'s call helps you, tip them in BNP from the Update. '
        'If you research projects yourself, apply to become a Hunter and '
        'post Updates for the Gems assigned to you.',
    actionLabel: 'Become a Hunter',
    route: AppRoutes.becomeHunter,
  ),
  GettingStartedStep(
    icon: Icons.account_balance_wallet_outlined,
    title: 'Know your wallet',
    body:
        'The Wallet tab holds your BNP balance and your custody address. BNT, '
        'the Blocnet Token, launches on BNB Smart Chain; at launch your BNP '
        'converts to BNT. Until then balances are pre-launch.',
    actionLabel: 'Open Wallet',
    route: AppRoutes.wallet,
  ),
];
