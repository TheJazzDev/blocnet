import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/hunter/data/models/hunter_board_model.dart';
import 'package:blocnet/features/hunter/data/models/project_invite_model.dart';
import 'package:blocnet/features/hunter/domain/hub_format.dart';
import 'package:blocnet/features/hunter/domain/hub_layout.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/answers/invite_card.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/answers/review_card.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/board/hub_gem_list.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/board/hub_identity_row.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/board/hub_standing_card.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/board/reach_row.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/day_one/day_one_card.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/day_one/reliability_explainer.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_section_header.dart';
import 'package:blocnet/features/projects/data/models/project_proposal_model.dart';
import 'package:flutter/material.dart';

/// What the Hub can ask its host to do.
class HubBoardActions {
  const HubBoardActions({
    required this.onOpenGem,
    required this.onPostUpdate,
    required this.onSubmitGem,
    required this.onRespondToInvite,
    required this.isResponding,
  });

  final ValueChanged<HunterBoardGem> onOpenGem;
  final ValueChanged<HunterBoardGem> onPostUpdate;
  final VoidCallback onSubmitGem;
  final void Function(ProjectInviteModel invite, bool accept) onRespondToInvite;
  final bool Function(String inviteId) isResponding;
}

/// The Hub body, rendered from data alone (design states 1–5).
///
/// Nothing here is a mode: day one, the answers section, the attention rows,
/// the fold and the reach row each appear because the data says so.
class HubBoardView extends StatefulWidget {
  const HubBoardView({
    super.key,
    required this.board,
    required this.identity,
    required this.invites,
    required this.proposals,
    required this.now,
    required this.actions,
    required this.onRefresh,
  });

  final HunterBoard board;
  final HubIdentity identity;

  /// Pending invites only.
  final List<ProjectInviteModel> invites;

  /// Submissions in review only.
  final List<ProjectProposalModel> proposals;
  final DateTime now;
  final HubBoardActions actions;
  final Future<void> Function() onRefresh;

  /// Room left under the list for the extended FAB.
  static const double fabClearance = 96;

  @override
  State<HubBoardView> createState() => _HubBoardViewState();
}

class _HubBoardViewState extends State<HubBoardView> {
  final GlobalKey _answersKey = GlobalKey();

  void _scrollToAnswers() {
    final target = _answersKey.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasAnswers = widget.invites.isNotEmpty || widget.proposals.isNotEmpty;
    final layout = HubLayout(
      board: widget.board,
      hasPendingAnswers: hasAnswers,
      now: widget.now,
    );
    final reliability = layout.reliability;

    final children = <Widget>[
      HubIdentityRow(
        key: const ValueKey('hub-identity'),
        identity: widget.identity,
        bottomPadding: layout.foldsCurrent ? 12 : 16,
      ),
      if (layout.isDayOne) ...[
        DayOneCard(
          key: const ValueKey('hub-day-one'),
          onSubmitGem: widget.actions.onSubmitGem,
          onShowInvites: widget.invites.isEmpty ? null : _scrollToAnswers,
        ),
        if (hasAnswers) ..._answers(),
        const HubSectionHeader(
          key: ValueKey('hub-section-standing'),
          label: 'Standing',
        ),
        HubStandingCard(
          key: const ValueKey('hub-reliability'),
          layout: layout,
        ),
        const HubSectionHeader(
          key: ValueKey('hub-section-measured'),
          label: 'How reliability is measured',
        ),
        const ReliabilityExplainer(key: ValueKey('hub-measured')),
      ] else ...[
        HubStandingCard(
          key: const ValueKey('hub-reliability'),
          layout: layout,
        ),
        if (layout.showsReach)
          ReachRow(
            key: const ValueKey('hub-reach'),
            tips: formatTips(
                  reliability.tipsReceivedTotal,
                  reliability.tipsCurrencyCode,
                  reliability.tipsCurrencyDecimals,
                ) ??
                '0',
            followers: groupedCount(reliability.followersTotal),
          ),
        if (hasAnswers) ..._answers(),
        HubGemList(
          layout: layout,
          onOpenGem: widget.actions.onOpenGem,
          onPostUpdate: widget.actions.onPostUpdate,
        ),
      ],
      const SizedBox(height: HubBoardView.fabClearance),
    ];

    return RefreshIndicator(
      color: AppColors.hunterAccent,
      backgroundColor: AppColors.bgSurface,
      onRefresh: widget.onRefresh,
      child: SingleChildScrollView(
        key: const ValueKey('hub-scroll'),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }

  List<Widget> _answers() {
    return [
      HubSectionHeader(
        key: _answersKey,
        label: 'Needs your answer',
        icon: Icons.mail_outline_rounded,
      ),
      for (final invite in widget.invites)
        InviteCard(
          key: ValueKey('hub-invite-${invite.id}'),
          invite: invite,
          now: widget.now,
          busy: widget.actions.isResponding(invite.id),
          onAccept: () => widget.actions.onRespondToInvite(invite, true),
          onDecline: () => widget.actions.onRespondToInvite(invite, false),
        ),
      for (final proposal in widget.proposals)
        ReviewCard(
          key: ValueKey('hub-review-${proposal.id}'),
          proposal: proposal,
          now: widget.now,
        ),
    ];
  }
}
