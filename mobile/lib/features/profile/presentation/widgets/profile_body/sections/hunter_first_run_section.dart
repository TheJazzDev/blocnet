import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';

/// What a hunter sees in place of the metric wall before their first update.
///
/// Success rate, sentiment, the trust chips, community voice and the signals
/// list are all derived from updates the hunter has posted. With none posted
/// they render as six zeroes and three "N/A"s, which tells a new hunter
/// nothing and reads as failure. One sentence about what the section will
/// show, plus the action that starts it, replaces the lot.
class HunterFirstRunSection extends StatelessWidget {
  const HunterFirstRunSection({
    super.key,
    required this.hasManagedProject,
  });

  /// A hunter with no gem cannot post an update yet, so the next step is
  /// submitting one rather than writing an update with nowhere to put it.
  final bool hasManagedProject;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpace.lg, AppSpace.lg, AppSpace.lg, 0),
      child: AppSurface(
        padding: AppSpace.allLg,
        child: AppEmptyState(
          compact: true,
          icon: Icons.insights_outlined,
          title: 'Your hunter stats start with your first update',
          message: hasManagedProject
              ? 'Post an update on a gem you manage and this space fills in '
                  'with how often you post, how the community responds, and '
                  'your most recent signals.'
              : 'Submit a gem to start hunting. Once you post updates on it, '
                  'this space fills in with how often you post, how the '
                  'community responds, and your most recent signals.',
          actionLabel: hasManagedProject ? 'Post an update' : 'Submit a gem',
          onAction: () => Navigator.of(context).pushNamed(
            hasManagedProject
                ? AppRoutes.createUpdate
                : AppRoutes.submitProject,
          ),
        ),
      ),
    );
  }
}
