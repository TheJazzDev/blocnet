import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/hunter/data/models/project_invite_model.dart';
import 'package:blocnet/features/hunter/domain/hub_format.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/answers/answer_card_frame.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_button.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_pill.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_styles.dart';
import 'package:flutter/material.dart';

/// An invite to take over a gem's coverage: who is handing it over, what it
/// carries, and Accept / Decline at equal weight.
class InviteCard extends StatelessWidget {
  const InviteCard({
    super.key,
    required this.invite,
    required this.now,
    required this.busy,
    required this.onAccept,
    required this.onDecline,
  });

  final ProjectInviteModel invite;
  final DateTime now;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return AnswerCardFrame(
      name: invite.projectName,
      tag: invite.primaryTag ?? '',
      highlighted: true,
      pill: HubPill(
        label: 'Invite',
        color: AppColors.inviteViolet,
        background: AppColors.inviteViolet.withValues(alpha: 0.14),
      ),
      body: Text.rich(
        TextSpan(children: inviteSentence(invite, now)),
        style: HubType.meta(AppColors.zincFaint).copyWith(height: 1.55),
      ),
      actions: Row(
        children: [
          Expanded(
            child: HubButton(
              label: 'Accept',
              small: true,
              busy: busy,
              onTap: onAccept,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: HubButton(
              label: 'Decline',
              small: true,
              tone: HubButtonTone.outline,
              onTap: busy ? null : onDecline,
            ),
          ),
        ],
      ),
    );
  }
}

/// `@abtoonzz is handing over coverage. 12,740 followers, 34 updates posted,
/// last one 2 days ago. Accept and the obligation is yours.` Clauses the
/// backend did not send are left out rather than guessed.
List<InlineSpan> inviteSentence(ProjectInviteModel invite, DateTime now) {
  final handle = invite.inviterUsername;
  final facts = [
    if (invite.followersCount != null)
      counted(invite.followersCount!, 'follower'),
    if (invite.updatesCount != null)
      '${counted(invite.updatesCount!, 'update')} posted',
    if (invite.lastUpdateAt != null)
      'last one ${daysAgoSince(invite.lastUpdateAt!, now)}',
  ];
  const bold = TextStyle(
    color: AppColors.zincBody,
    fontWeight: FontWeight.w600,
  );
  return [
    if (handle != null) ...[
      TextSpan(text: '@$handle', style: bold),
      const TextSpan(text: ' is handing over coverage. '),
    ] else
      const TextSpan(text: 'You are invited to take over coverage. '),
    if (facts.isNotEmpty) TextSpan(text: '${capitalized(facts.join(', '))}. '),
    const TextSpan(text: 'Accept and the obligation is yours.'),
  ];
}
