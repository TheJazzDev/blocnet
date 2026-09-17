import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/community/data/models/community_moderation_models.dart';
import 'package:blocnet/features/moderation/presentation/widgets/common/mod_parts.dart';
import 'package:blocnet/features/moderation/presentation/widgets/common/mod_styles.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A member's current standing: name, email, then one row per sanction.
/// A sanction that has lapsed or never applied reads "None".
class MemberStateCard extends StatelessWidget {
  const MemberStateCard({super.key, required this.state, this.now});

  final CommunityModerationUserState state;

  /// Injectable for tests.
  final DateTime? now;

  String _until(DateTime? value) {
    if (value == null) return 'None';
    final local = value.toLocal();
    if (local.isBefore(now ?? DateTime.now())) return 'None';
    return 'Until ${DateFormat('MMM d, HH:mm').format(local)}';
  }

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String, bool)>[
      (
        'Warnings',
        '${state.communityWarnCount}',
        state.communityWarnCount > 0,
      ),
      _row('Muted', state.communityMutedUntil),
      _row('Suspended', state.communitySuspendedUntil),
      _row('Posting blocked', state.communityPostingRestrictedUntil),
      _row('Comments blocked', state.communityCommentingRestrictedUntil),
    ];
    return AppSurface(
      tone: AppSurfaceTone.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            state.bestLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ModText.rowTitle(AppColors.textPrimary),
          ),
          if (state.email.isNotEmpty)
            Text(
              state.email,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ModText.meta(AppColors.textMuted),
            ),
          AppSpace.gapMd,
          for (final (label, value, active) in rows)
            Padding(
              padding: const EdgeInsets.only(top: AppSpace.xs),
              child: Row(
                children: [
                  Expanded(
                    child: Text(label, style: ModText.meta(AppColors.textMuted)),
                  ),
                  Text(
                    value,
                    style: AppText.label(
                      active ? ModTone.open : AppColors.textSecondary,
                      weight: AppText.semibold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  (String, String, bool) _row(String label, DateTime? until) {
    final value = _until(until);
    return (label, value, value != 'None');
  }
}
