import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/community/data/models/community_moderation_models.dart';
import 'package:blocnet/features/moderation/presentation/widgets/common/mod_dropdown.dart';
import 'package:blocnet/features/moderation/presentation/widgets/common/mod_parts.dart';
import 'package:blocnet/features/moderation/presentation/widgets/common/mod_styles.dart';
import 'package:flutter/material.dart';

/// Search plus status and target filters, on the page background with a
/// hairline underneath.
class ReportFilterBar extends StatelessWidget {
  const ReportFilterBar({
    super.key,
    required this.searchController,
    required this.statusFilter,
    required this.targetTypeFilter,
    required this.onStatusChanged,
    required this.onTargetTypeChanged,
    required this.isLoading,
  });

  final TextEditingController searchController;
  final CommunityReportStatus? statusFilter;
  final CommunityReportTargetType? targetTypeFilter;
  final ValueChanged<CommunityReportStatus?> onStatusChanged;
  final ValueChanged<CommunityReportTargetType?> onTargetTypeChanged;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        ModTone.gutter,
        AppSpace.md,
        ModTone.gutter,
        AppSpace.md,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 40,
            child: TextField(
              controller: searchController,
              textInputAction: TextInputAction.search,
              style: AppText.body(AppColors.textPrimary),
              decoration: modInputDecoration(hint: 'Search reports').copyWith(
                fillColor: AppColors.bgElevated,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.md,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: AppIcon.md,
                  color: AppColors.textMuted,
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 40),
                suffixIcon: isLoading ? const _SearchSpinner() : null,
                suffixIconConstraints: const BoxConstraints(minWidth: 40),
              ),
            ),
          ),
          AppSpace.gapMd,
          Row(
            children: [
              Expanded(
                child: ModDropdown<CommunityReportStatus?>(
                  label: 'Status',
                  value: statusFilter,
                  options: const {
                    null: 'All',
                    CommunityReportStatus.open: 'Open',
                    CommunityReportStatus.resolved: 'Resolved',
                    CommunityReportStatus.dismissed: 'Dismissed',
                  },
                  onChanged: onStatusChanged,
                ),
              ),
              AppSpace.wGapSm,
              Expanded(
                child: ModDropdown<CommunityReportTargetType?>(
                  label: 'Target',
                  value: targetTypeFilter,
                  options: const {
                    null: 'All',
                    CommunityReportTargetType.communityPost: 'Post',
                    CommunityReportTargetType.communityComment: 'Comment',
                    CommunityReportTargetType.userProfile: 'Profile',
                  },
                  onChanged: onTargetTypeChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SearchSpinner extends StatelessWidget {
  const _SearchSpinner();

  @override
  Widget build(BuildContext context) {
    return const Center(
      widthFactor: 1,
      child: SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: ModTone.accent,
        ),
      ),
    );
  }
}
