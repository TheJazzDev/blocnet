import 'package:flutter/material.dart';

/// One glossary term. Static copy rendered by the Glossary screen.
class GlossaryTerm {
  const GlossaryTerm({
    required this.term,
    required this.definition,
    required this.icon,
    this.expansion,
  });

  final String term;

  /// Spelled-out form for acronyms (e.g. "Blocnet Point").
  final String? expansion;
  final String definition;
  final IconData icon;
}

/// Vocabulary rule: users find Gems, admins create Projects, hunters post
/// Updates. The same thing is never called two things in front of a user.
const List<GlossaryTerm> glossaryTerms = [
  GlossaryTerm(
    term: 'Gem',
    icon: Icons.diamond_outlined,
    definition:
        'A crypto project listed on Blocnet. You find Gems in Discover, '
        'follow them, and their Updates fill your Home feed. Hunters submit '
        'new Gems and the Blocnet team approves them before listing.',
  ),
  GlossaryTerm(
    term: 'Hunter',
    icon: Icons.radar_rounded,
    definition: 'A vetted member who tracks Gems, posts Updates about them and '
        'submits new Gems. Hunters have a public track record and can be '
        'tipped for good calls. Apply from Profile > Become a Hunter.',
  ),
  GlossaryTerm(
    term: 'Update',
    icon: Icons.bolt_rounded,
    definition: 'A post by a Hunter about one Gem: news, on-chain activity, '
        'partnerships, airdrops or warnings, with a priority of High, Medium '
        'or Low. You can like, comment on, bookmark, share and tip an Update.',
  ),
  GlossaryTerm(
    term: 'Alpha Radar',
    icon: Icons.track_changes_rounded,
    definition:
        'The strip at the top of Home that shows which of your followed '
        'Gems are most active right now.',
  ),
  GlossaryTerm(
    term: 'Edge brief',
    icon: Icons.insights_rounded,
    definition: 'A short, scored summary produced by Edge, Blocnet\'s decision '
        'engine, from the latest Updates of the Gems you follow: what '
        'changed, how urgent it is and why.',
  ),
  GlossaryTerm(
    term: 'Space',
    icon: Icons.swap_horiz_rounded,
    definition:
        'A view of the app for one of your roles: User for everyone, Hunter '
        'for hunters (Hunter Hub and posting tools) and Moderation for '
        'moderators. Switch with the chip in the top-right corner; your '
        'profile, badges, quests and levels are the same in every space.',
  ),
  GlossaryTerm(
    term: 'BNP',
    expansion: 'Blocnet Point',
    icon: Icons.toll_rounded,
    definition: 'What you mine, earn from quests and tip with today. BNP is an '
        'in-app point, not a token on chain.',
  ),
  GlossaryTerm(
    term: 'BNT',
    expansion: 'Blocnet Token',
    icon: Icons.token_outlined,
    definition:
        'The Blocnet Token, launching on BNB Smart Chain. When BNT launches '
        'your BNP converts to BNT. Until then the wallet shows pre-launch '
        'balances.',
  ),
  GlossaryTerm(
    term: 'Tip',
    icon: Icons.volunteer_activism_outlined,
    definition:
        'BNP you send to a Hunter from an Update or their profile to reward '
        'a good call. A small platform fee is deducted. Your sent tips are '
        'listed under Profile > Tip History.',
  ),
];
