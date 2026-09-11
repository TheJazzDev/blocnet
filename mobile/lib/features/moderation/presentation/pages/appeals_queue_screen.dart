import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/moderation/data/models/community_appeal_model.dart';
import 'package:blocnet/services/api/api_client.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppealsQueueScreen extends StatefulWidget {
  const AppealsQueueScreen({super.key});

  @override
  State<AppealsQueueScreen> createState() => _AppealsQueueScreenState();
}

class _AppealsQueueScreenState extends State<AppealsQueueScreen> {
  final ApiClient _apiClient = ApiClient();
  List<CommunityAppeal> _appeals = [];
  bool _isLoading = false;
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _loadAppeals();
  }

  Future<void> _loadAppeals() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final queryParams = <String, String>{
        'limit': '50',
      };
      if (_statusFilter != null) {
        queryParams['status'] = _statusFilter!;
      }

      final response = await _apiClient.get(
        '/community/moderation/appeals',
        query: queryParams,
      );

      if (!mounted) return;
      setState(() {
        _appeals = (response['appeals'] as List)
            .map((a) => CommunityAppeal.fromApi(a as Map<String, dynamic>))
            .toList();
      });
    } catch (e) {
      if (!mounted) return;
      debugPrint('Failed to load appeals: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onStatusFilterChanged(String? value) {
    setState(() => _statusFilter = value);
    _loadAppeals();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        backgroundColor: AppColors.bgBase,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Appeals Queue',
          style: AppTypography.custom(
            color: AppColors.textPrimary,
            size: AppText.subtitleSize,
            weight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter bar
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.lg, vertical: AppSpace.md),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              border: Border(
                bottom: BorderSide(color: AppColors.borderSubtle),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Status:',
                  style: AppTypography.custom(
                    color: AppColors.textMuted,
                    size: AppText.captionSize,
                    weight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Container(
                    height: 36,
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpace.md),
                    decoration: BoxDecoration(
                      color: AppColors.bgBase,
                      borderRadius: BorderRadius.circular(AppRadius.smValue),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _statusFilter,
                        isExpanded: true,
                        hint: Text(
                          'All Statuses',
                          style: AppTypography.custom(
                            color: AppColors.textMuted,
                            size: AppText.bodySize,
                            weight: FontWeight.w400,
                          ),
                        ),
                        style: AppTypography.custom(
                          color: AppColors.textPrimary,
                          size: AppText.labelSize,
                          weight: FontWeight.w500,
                        ),
                        icon: Icon(Icons.arrow_drop_down,
                            size: AppIcon.md, color: AppColors.textMuted),
                        items: const [
                          DropdownMenuItem(
                              value: null, child: Text('All Statuses')),
                          DropdownMenuItem(
                              value: 'pending', child: Text('Pending')),
                          DropdownMenuItem(
                              value: 'under_review',
                              child: Text('Under Review')),
                          DropdownMenuItem(
                              value: 'approved', child: Text('Approved')),
                          DropdownMenuItem(
                              value: 'rejected', child: Text('Rejected')),
                        ],
                        onChanged: _onStatusFilterChanged,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Appeals list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _appeals.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.gavel_outlined,
                              size: AppIcon.xxl,
                              color: AppColors.textMuted.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: AppSpace.md),
                            Text(
                              'No appeals found',
                              style: AppTypography.custom(
                                color: AppColors.textMuted,
                                size: AppText.labelSize,
                                weight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadAppeals,
                        color: AppColors.moderationAccent,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(AppSpace.lg),
                          itemCount: _appeals.length,
                          itemBuilder: (context, index) {
                            return _AppealCard(
                              appeal: _appeals[index],
                              onReviewed: _loadAppeals,
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _AppealCard extends StatelessWidget {
  final CommunityAppeal appeal;
  final VoidCallback onReviewed;

  const _AppealCard({
    required this.appeal,
    required this.onReviewed,
  });

  Color _getStatusColor() {
    switch (appeal.status) {
      case CommunityAppealStatus.pending:
        return AppColors.warning500;
      case CommunityAppealStatus.underReview:
        return AppColors.primary400;
      case CommunityAppealStatus.approved:
        return AppColors.successColor;
      case CommunityAppealStatus.rejected:
        return AppColors.error500;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();

    return AppSurface.flush(
      margin: const EdgeInsets.only(bottom: AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppSpace.md),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.sm, vertical: AppSpace.hair),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(AppRadius.smValue),
                  ),
                  child: Text(
                    appeal.statusLabel.toUpperCase(),
                    style: AppTypography.custom(
                      color: Colors.black,
                      size: AppText.captionSize,
                      weight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Text(
                    'Appeal #${appeal.id.substring(0, 8)}',
                    style: AppTypography.custom(
                      color: AppColors.textPrimary,
                      size: AppText.labelSize,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  DateFormat('MMM d, HH:mm').format(appeal.createdAt.toLocal()),
                  style: AppTypography.custom(
                    color: AppColors.textMuted,
                    size: AppText.captionSize,
                    weight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(AppSpace.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Appealer info
                Row(
                  children: [
                    Icon(Icons.person_outline,
                        size: AppIcon.sm, color: AppColors.textMuted),
                    const SizedBox(width: AppSpace.sm),
                    Text(
                      appeal.appealer?.username ?? 'Unknown',
                      style: AppTypography.custom(
                        color: AppColors.textPrimary,
                        size: AppText.labelSize,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.sm),

                // Appeal reason
                Text(
                  'Reason:',
                  style: AppTypography.custom(
                    color: AppColors.textMuted,
                    size: AppText.captionSize,
                    weight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpace.xs),
                Text(
                  appeal.reason,
                  style: AppTypography.custom(
                    color: AppColors.textSecondary,
                    size: AppText.bodySize,
                    weight: FontWeight.w400,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),

                // Original report info
                if (appeal.report != null) ...[
                  const SizedBox(height: AppSpace.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpace.md),
                    decoration: BoxDecoration(
                      color: AppColors.bgBase,
                      borderRadius: BorderRadius.circular(AppRadius.smValue),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Original Report',
                          style: AppTypography.custom(
                            color: AppColors.textMuted,
                            size: AppText.captionSize,
                            weight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpace.sm),
                        Text(
                          'Category: ${appeal.report!.category}',
                          style: AppTypography.custom(
                            color: AppColors.textSecondary,
                            size: AppText.captionSize,
                            weight: FontWeight.w400,
                          ),
                        ),
                        if (appeal.report!.reviewNotes != null)
                          Text(
                            'Notes: ${appeal.report!.reviewNotes}',
                            style: AppTypography.custom(
                              color: AppColors.textSecondary,
                              size: AppText.captionSize,
                              weight: FontWeight.w400,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],

                // Review info (if reviewed)
                if (appeal.reviewedBy != null) ...[
                  const SizedBox(height: AppSpace.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpace.md),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(AppRadius.smValue),
                      border:
                          Border.all(color: statusColor.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.check_circle_outline,
                                size: AppIcon.sm, color: statusColor),
                            const SizedBox(width: AppSpace.sm),
                            Text(
                              'Reviewed by ${appeal.reviewedBy!.username}',
                              style: AppTypography.custom(
                                color: statusColor,
                                size: AppText.captionSize,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        if (appeal.decision != null) ...[
                          const SizedBox(height: AppSpace.xs),
                          Text(
                            'Decision: ${appeal.decisionLabel}',
                            style: AppTypography.custom(
                              color: AppColors.textSecondary,
                              size: AppText.captionSize,
                              weight: FontWeight.w500,
                            ),
                          ),
                        ],
                        if (appeal.reviewNotes != null) ...[
                          const SizedBox(height: AppSpace.xs),
                          Text(
                            appeal.reviewNotes!,
                            style: AppTypography.custom(
                              color: AppColors.textSecondary,
                              size: AppText.captionSize,
                              weight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                // Action buttons (only for pending/under_review)
                if (appeal.status == CommunityAppealStatus.pending ||
                    appeal.status == CommunityAppealStatus.underReview) ...[
                  const SizedBox(height: AppSpace.md),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              _showReviewDialog(context, appeal, 'overturn'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.successColor,
                            side: BorderSide(color: AppColors.successColor),
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpace.md),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.smValue),
                            ),
                          ),
                          child: Text(
                            'Overturn',
                            style: AppTypography.custom(
                              color: AppColors.successColor,
                              size: AppText.labelSize,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              _showReviewDialog(context, appeal, 'uphold'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error500,
                            side: BorderSide(color: AppColors.error500),
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpace.md),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.smValue),
                            ),
                          ),
                          child: Text(
                            'Uphold',
                            style: AppTypography.custom(
                              color: AppColors.error500,
                              size: AppText.labelSize,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showReviewDialog(
      BuildContext context, CommunityAppeal appeal, String decision) {
    final TextEditingController notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgSurface,
        title: Text(
          decision == 'overturn'
              ? 'Overturn Appeal'
              : 'Uphold Original Decision',
          style: AppTypography.custom(
            color: AppColors.textPrimary,
            size: AppText.bodySize,
            weight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Review Notes (optional)',
              style: AppTypography.custom(
                color: AppColors.textMuted,
                size: AppText.labelSize,
                weight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            TextField(
              controller: notesController,
              maxLines: 3,
              style: AppTypography.custom(
                color: AppColors.textPrimary,
                size: AppText.bodySize,
                weight: FontWeight.w400,
              ),
              decoration: InputDecoration(
                hintText: 'Add notes about your decision...',
                hintStyle: AppTypography.custom(
                  color: AppColors.textMuted,
                  size: AppText.bodySize,
                  weight: FontWeight.w400,
                ),
                filled: true,
                fillColor: AppColors.bgBase,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.smValue),
                  borderSide: const BorderSide(color: AppColors.borderSubtle),
                ),
                contentPadding: const EdgeInsets.all(AppSpace.md),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: AppTypography.custom(
                color: AppColors.textMuted,
                size: AppText.labelSize,
                weight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _submitReview(
                  context, appeal, decision, notesController.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: decision == 'overturn'
                  ? AppColors.successColor
                  : AppColors.error500,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.lg, vertical: AppSpace.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.smValue),
              ),
            ),
            child: Text(
              'Confirm',
              style: AppTypography.custom(
                color: Colors.white,
                size: AppText.labelSize,
                weight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitReview(
    BuildContext context,
    CommunityAppeal appeal,
    String decision,
    String notes,
  ) async {
    try {
      final apiClient = ApiClient();
      await apiClient.patch(
        '/community/moderation/appeals/${appeal.id}',
        body: {
          'decision': decision,
          if (notes.isNotEmpty) 'reviewNotes': notes,
        },
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Appeal ${decision}ed successfully'),
          backgroundColor: AppColors.successColor,
        ),
      );

      onReviewed();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to review appeal: $e'),
          backgroundColor: AppColors.error500,
        ),
      );
    }
  }
}
