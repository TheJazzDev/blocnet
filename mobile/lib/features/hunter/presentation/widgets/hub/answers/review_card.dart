import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/hunter/domain/hub_format.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/answers/answer_card_frame.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_pill.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_styles.dart';
import 'package:blocnet/features/projects/data/models/project_proposal_model.dart';
import 'package:flutter/material.dart';

/// A submission still in review. Says where it is without inventing a queue
/// position.
class ReviewCard extends StatelessWidget {
  const ReviewCard({super.key, required this.proposal, required this.now});

  final ProjectProposalModel proposal;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return AnswerCardFrame(
      name: proposal.name,
      tag: '',
      pill: const HubPill(
        label: 'In review',
        color: AppColors.zincMuted,
        background: AppColors.borderSubtle,
      ),
      body: Text(
        'Submitted ${daysAgoSince(proposal.createdAt, now)}. A moderator is '
        "checking the diligence. You'll get a notification either way.",
        style: HubType.meta(AppColors.zincFaint).copyWith(height: 1.55),
      ),
    );
  }
}
