import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/community/data/models/community_moderation_models.dart';
import 'package:blocnet/features/community/data/repositories/community_moderation_api_repository.dart';
import 'package:blocnet/features/community/presentation/widgets/community_content_moderation_sheet.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/api/api_client.dart';
import 'package:blocnet/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ReportsQueueScreen extends StatefulWidget {
  const ReportsQueueScreen({super.key});

  @override
  State<ReportsQueueScreen> createState() =>
      _ReportsQueueScreenState();
}

class _ReportsQueueScreenState extends State<ReportsQueueScreen> {
  static const int _pageSize = 20;

  final CommunityModerationApiRepository _repository =
      CommunityModerationApiRepository();
  final TextEditingController _searchController = TextEditingController();

  CommunityReportStatus? _statusFilter;
  CommunityReportTargetType? _targetTypeFilter;

  bool _isLoading = false;
  bool _isReviewing = false;
  String? _error;
  int _offset = 0;
  int _total = 0;
  List<CommunityModerationReport> _reports = const [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
    _loadReports(resetOffset: true);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    if (_searchController.text.trim().length == 1) return;
    _loadReports(resetOffset: true);
  }

  Future<void> _loadReports({bool resetOffset = false}) async {
    if (_isLoading) return;
    if (resetOffset) {
      _offset = 0;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final page = await _repository.fetchReports(
        limit: _pageSize,
        offset: _offset,
        q: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        status: _statusFilter,
        targetType: _targetTypeFilter,
      );

      if (!mounted) return;
      setState(() {
        _reports = page.reports;
        _total = page.total;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = _friendlyError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _friendlyError(Object error) {
    if (error is ApiException && error.message.trim().isNotEmpty) {
      return error.message.trim();
    }
    return error.toString();
  }

  bool get _canGoPrev => _offset > 0;
  bool get _canGoNext => _offset + _pageSize < _total;

  Future<void> _reviewReport(
    CommunityModerationReport report,
    CommunityReportStatus status,
  ) async {
    final note = await _showReasonDialog(
      context: context,
      title: status == CommunityReportStatus.resolved
          ? 'Resolve Report'
          : 'Dismiss Report',
      hint: 'Optional note',
      required: false,
    );

    if (note == null) return;
    setState(() => _isReviewing = true);
    try {
      await _repository.reviewReport(
        reportId: report.id,
        status: status,
        note: note.trim().isEmpty ? null : note.trim(),
      );
      if (!mounted) return;
      AppSnackbar.showSuccess(context, 'Report updated');
      await _loadReports();
    } catch (error) {
      if (!mounted) return;
      AppSnackbar.showError(context, _friendlyError(error));
    } finally {
      if (mounted) {
        setState(() => _isReviewing = false);
      }
    }
  }

  Future<void> _openUserActions(CommunityModerationReport report) async {
    final targetUserId = report.targetUserId?.trim().isNotEmpty == true
        ? report.targetUserId
        : null;
    if (targetUserId == null) {
      AppSnackbar.showError(context, 'This report has no target user.');
      return;
    }

    final auth = context.read<AuthStore>();
    final canEscalate =
        auth.isOwner || auth.isDev || auth.isAdmin || auth.isCommunityAdmin;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _CommunityUserActionsSheet(
        repository: _repository,
        report: report,
        targetUserId: targetUserId,
        canEscalate: canEscalate,
      ),
    );
  }

  Future<void> _moderateReportTarget(
    CommunityModerationReport report,
  ) async {
    final auth = context.read<AuthStore>();
    final decision = await showCommunityContentModerationSheet(
      context,
      targetLabel: report.targetType == CommunityReportTargetType.communityComment
          ? 'comment'
          : 'post',
      canArchive: auth.isCommunityAdmin,
    );
    if (decision == null) return;

    setState(() => _isReviewing = true);
    try {
      if (report.targetType == CommunityReportTargetType.communityComment) {
        await _repository.moderateCommunityCommentStatus(
          commentId: report.targetId,
          status: decision.status,
          reason: decision.reason,
        );
      } else if (report.targetType == CommunityReportTargetType.communityPost) {
        await _repository.moderateCommunityPostStatus(
          postId: report.targetId,
          status: decision.status,
          reason: decision.reason,
        );
      } else {
        if (!mounted) return;
        AppSnackbar.showError(
          context,
          'Content actions are only available for posts and comments.',
        );
        return;
      }

      if (!mounted) return;
      AppSnackbar.showSuccess(
        context,
        switch (decision.status) {
          CommunityContentModerationStatus.active => 'Content restored',
          CommunityContentModerationStatus.hidden => 'Content hidden',
          CommunityContentModerationStatus.archived => 'Content archived',
        },
      );
      await _loadReports();
    } catch (error) {
      if (!mounted) return;
      AppSnackbar.showError(context, _friendlyError(error));
    } finally {
      if (mounted) {
        setState(() => _isReviewing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final openCount = _reports.where((report) => report.isOpen).length;
    final contentCount = _reports
        .where(
          (report) =>
              report.targetType == CommunityReportTargetType.communityPost ||
              report.targetType == CommunityReportTargetType.communityComment,
        )
        .length;
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: const CustomAppBar(
        title: 'Staff Tools',
        backButton: true,
        showSearch: false,
        showFilter: false,
        showSpaceSwitcher: false,
        showNotificationBell: true,
      ),
      body: Column(
        children: [
          _FilterBar(
            searchController: _searchController,
            statusFilter: _statusFilter,
            targetTypeFilter: _targetTypeFilter,
            onStatusChanged: (value) {
              setState(() => _statusFilter = value);
              _loadReports(resetOffset: true);
            },
            onTargetTypeChanged: (value) {
              setState(() => _targetTypeFilter = value);
              _loadReports(resetOffset: true);
            },
            onRefresh: () => _loadReports(),
            isRefreshing: _isLoading,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 2),
            child: _StaffOverviewCard(
              openCount: openCount,
              contentCount: contentCount,
              total: _total,
            ),
          ),
          Expanded(
            child: _isLoading && _reports.isEmpty
                ? Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary500,
                    ),
                  )
                : _error != null && _reports.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: AppTypography.custom(
                              color: AppColors.error500,
                              size: 13,
                              weight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                    : _reports.isEmpty
                        ? Center(
                            child: Text(
                              'No reports found',
                              style: AppTypography.custom(
                                color: AppColors.textMuted,
                                size: 13,
                                weight: FontWeight.w500,
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                            itemBuilder: (context, index) {
                              final report = _reports[index];
                              return _ReportCard(
                                report: report,
                                reviewing: _isReviewing,
                                onResolve: report.isOpen
                                    ? () => _reviewReport(
                                          report,
                                          CommunityReportStatus.resolved,
                                        )
                                    : null,
                                onDismiss: report.isOpen
                                    ? () => _reviewReport(
                                          report,
                                          CommunityReportStatus.dismissed,
                                        )
                                    : null,
                                onContentActions:
                                    report.targetType ==
                                                CommunityReportTargetType
                                                    .communityPost ||
                                            report.targetType ==
                                                CommunityReportTargetType
                                                    .communityComment
                                        ? () => _moderateReportTarget(report)
                                        : null,
                                onUserActions: () => _openUserActions(report),
                              );
                            },
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemCount: _reports.length,
                          ),
          ),
          _PaginationBar(
            from: _reports.isEmpty ? 0 : _offset + 1,
            to: (_offset + _reports.length).clamp(0, _total),
            total: _total,
            canGoPrev: _canGoPrev && !_isLoading,
            canGoNext: _canGoNext && !_isLoading,
            onPrev: () {
              if (!_canGoPrev) return;
              setState(() => _offset = (_offset - _pageSize).clamp(0, _offset));
              _loadReports();
            },
            onNext: () {
              if (!_canGoNext) return;
              setState(() => _offset += _pageSize);
              _loadReports();
            },
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.searchController,
    required this.statusFilter,
    required this.targetTypeFilter,
    required this.onStatusChanged,
    required this.onTargetTypeChanged,
    required this.onRefresh,
    required this.isRefreshing,
  });

  final TextEditingController searchController;
  final CommunityReportStatus? statusFilter;
  final CommunityReportTargetType? targetTypeFilter;
  final ValueChanged<CommunityReportStatus?> onStatusChanged;
  final ValueChanged<CommunityReportTargetType?> onTargetTypeChanged;
  final VoidCallback onRefresh;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.bgSurface,
            AppColors.bgSurface.withValues(alpha: 0.88),
          ],
        ),
        border: Border(
          bottom: BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Queue Filters',
            style: AppTypography.custom(
              color: AppColors.textMuted,
              size: 11,
              weight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 46,
            child: TextField(
              controller: searchController,
              style: AppTypography.custom(
                color: AppColors.textPrimary,
                size: 13,
                weight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Search reports',
                hintStyle: AppTypography.custom(
                  color: AppColors.textMuted,
                  size: 12,
                  weight: FontWeight.w400,
                ),
                prefixIcon: Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
                prefixIconConstraints: const BoxConstraints(minWidth: 40),
                suffixIcon: isRefreshing
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary500,
                          ),
                        ),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _DropdownField<CommunityReportStatus?>(
                  value: statusFilter,
                  label: 'Status',
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All')),
                    DropdownMenuItem(
                      value: CommunityReportStatus.open,
                      child: Text('Open'),
                    ),
                    DropdownMenuItem(
                      value: CommunityReportStatus.resolved,
                      child: Text('Resolved'),
                    ),
                    DropdownMenuItem(
                      value: CommunityReportStatus.dismissed,
                      child: Text('Dismissed'),
                    ),
                  ],
                  onChanged: onStatusChanged,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _DropdownField<CommunityReportTargetType?>(
                  value: targetTypeFilter,
                  label: 'Target',
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All')),
                    DropdownMenuItem(
                      value: CommunityReportTargetType.communityPost,
                      child: Text('Post'),
                    ),
                    DropdownMenuItem(
                      value: CommunityReportTargetType.communityComment,
                      child: Text('Comment'),
                    ),
                    DropdownMenuItem(
                      value: CommunityReportTargetType.userProfile,
                      child: Text('Profile'),
                    ),
                  ],
                  onChanged: onTargetTypeChanged,
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                height: 40,
                width: 40,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.bgElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.borderSubtle.withValues(alpha: 0.75),
                    ),
                  ),
                  child: IconButton(
                    onPressed: isRefreshing ? null : onRefresh,
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.refresh_rounded,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.value,
    required this.label,
    required this.items,
    required this.onChanged,
  });

  final T value;
  final String label;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 4),
          child: Text(
            label,
            style: AppTypography.custom(
              color: AppColors.textMuted,
              size: 10,
              weight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.bgElevated,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.borderSubtle.withValues(alpha: 0.8),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              dropdownColor: AppColors.bgSurface,
              items: items,
              onChanged: onChanged,
              style: AppTypography.custom(
                color: AppColors.textPrimary,
                size: 12,
                weight: FontWeight.w600,
              ),
              iconSize: 18,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.report,
    required this.reviewing,
    required this.onResolve,
    required this.onDismiss,
    required this.onContentActions,
    required this.onUserActions,
  });

  final CommunityModerationReport report;
  final bool reviewing;
  final VoidCallback? onResolve;
  final VoidCallback? onDismiss;
  final VoidCallback? onContentActions;
  final VoidCallback onUserActions;

  Color _statusColor(CommunityReportStatus status) {
    switch (status) {
      case CommunityReportStatus.open:
        return AppColors.warning500;
      case CommunityReportStatus.resolved:
        return Colors.green;
      case CommunityReportStatus.dismissed:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final targetLabel = report.targetUser?.bestLabel ??
        report.targetUserId ??
        report.targetType.label;
    final statusColor = _statusColor(report.status);
    final actions = <Widget>[
      if (onContentActions != null)
        _ReportActionButton(
          label: 'Content Actions',
          icon: Icons.visibility_outlined,
          variant: _ReportActionButtonVariant.outline,
          onPressed: reviewing ? null : onContentActions,
        ),
      if (onResolve != null)
        _ReportActionButton(
          label: 'Resolve',
          icon: Icons.check_circle_outline,
          variant: _ReportActionButtonVariant.success,
          onPressed: reviewing ? null : onResolve,
        ),
      if (onDismiss != null)
        _ReportActionButton(
          label: 'Dismiss',
          icon: Icons.close_rounded,
          variant: _ReportActionButtonVariant.outline,
          onPressed: reviewing ? null : onDismiss,
        ),
      if (report.targetUserId != null)
        _ReportActionButton(
          label: 'User Actions',
          icon: Icons.person_outline_rounded,
          variant: _ReportActionButtonVariant.primary,
          onPressed: reviewing ? null : onUserActions,
        ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.borderSubtle.withValues(alpha: 0.75),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  report.reason,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.custom(
                    color: AppColors.textPrimary,
                    size: 13,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  report.status.label.toUpperCase(),
                  style: AppTypography.custom(
                    color: statusColor,
                    size: 10,
                    weight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaPill(
                icon: Icons.flag_outlined,
                label: report.targetType.label,
                value: targetLabel,
              ),
              _MetaPill(
                icon: Icons.person_outline_rounded,
                label: 'Reporter',
                value: report.reporter.bestLabel,
              ),
            ],
          ),
          if ((report.details ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.bgElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.borderSubtle.withValues(alpha: 0.65),
                ),
              ),
              child: Text(
                report.details!,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.custom(
                  color: AppColors.textSecondary,
                  size: 11,
                  weight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = (constraints.maxWidth - 8) / 2;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: actions
                    .map((action) => SizedBox(width: width, child: action))
                    .toList(growable: false),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StaffOverviewCard extends StatelessWidget {
  const _StaffOverviewCard({
    required this.openCount,
    required this.contentCount,
    required this.total,
  });

  final int openCount;
  final int contentCount;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.bgSurface,
            AppColors.bgSurface.withValues(alpha: 0.85),
          ],
        ),
        border: Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.75)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary400.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(
                    Icons.gavel_rounded,
                    size: 16,
                    color: AppColors.primary400,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Community moderation queue',
                      style: AppTypography.custom(
                        color: AppColors.textPrimary,
                        size: 13,
                        weight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Review reports, hide content, and take action.',
                      style: AppTypography.custom(
                        color: AppColors.textMuted,
                        size: 11,
                        weight: FontWeight.w400,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _OverviewStat(
                  label: 'Open',
                  value: '$openCount',
                  color: AppColors.warning500,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _OverviewStat(
                  label: 'Content',
                  value: '$contentCount',
                  color: AppColors.primary400,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _OverviewStat(
                  label: 'Total',
                  value: '$total',
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewStat extends StatelessWidget {
  const _OverviewStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppTypography.custom(
              color: AppColors.textPrimary,
              size: 16,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: AppTypography.custom(
              color: AppColors.textMuted,
              size: 10,
              weight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderSubtle.withValues(alpha: 0.65),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: AppTypography.custom(
              color: AppColors.textMuted,
              size: 11,
              weight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

enum _ReportActionButtonVariant { outline, primary, success }

class _ReportActionButton extends StatelessWidget {
  const _ReportActionButton({
    required this.label,
    required this.icon,
    required this.variant,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final _ReportActionButtonVariant variant;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final Color borderColor;
    final Color fillColor;
    final Color textColor;

    switch (variant) {
      case _ReportActionButtonVariant.primary:
        borderColor = AppColors.primary400.withValues(alpha: 0.24);
        fillColor = AppColors.primary400.withValues(alpha: 0.14);
        textColor = const Color(0xFFB9C6FF);
        break;
      case _ReportActionButtonVariant.success:
        borderColor = const Color(0xFF34D399).withValues(alpha: 0.24);
        fillColor = const Color(0xFF34D399).withValues(alpha: 0.12);
        textColor = const Color(0xFF86EFAC);
        break;
      case _ReportActionButtonVariant.outline:
        borderColor = AppColors.borderMuted;
        fillColor = AppColors.bgElevated;
        textColor = AppColors.textPrimary;
        break;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          height: 48,
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: textColor),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.custom(
                    color: textColor,
                    size: 12,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.from,
    required this.to,
    required this.total,
    required this.canGoPrev,
    required this.canGoNext,
    required this.onPrev,
    required this.onNext,
  });

  final int from;
  final int to;
  final int total;
  final bool canGoPrev;
  final bool canGoNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        border: Border(
          top: BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Showing $from-$to of $total',
              style: AppTypography.custom(
                color: AppColors.textMuted,
                size: 11,
                weight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            onPressed: canGoPrev ? onPrev : null,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          IconButton(
            onPressed: canGoNext ? onNext : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

class _CommunityUserActionsSheet extends StatefulWidget {
  const _CommunityUserActionsSheet({
    required this.repository,
    required this.report,
    required this.targetUserId,
    required this.canEscalate,
  });

  final CommunityModerationApiRepository repository;
  final CommunityModerationReport report;
  final String targetUserId;
  final bool canEscalate;

  @override
  State<_CommunityUserActionsSheet> createState() =>
      _CommunityUserActionsSheetState();
}

class _CommunityUserActionsSheetState
    extends State<_CommunityUserActionsSheet> {
  CommunityModerationUserState? _state;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final userState =
          await widget.repository.getUserState(widget.targetUserId);
      if (!mounted) return;
      setState(() => _state = userState);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _friendlyError(error));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _friendlyError(Object error) {
    if (error is ApiException && error.message.trim().isNotEmpty) {
      return error.message.trim();
    }
    return error.toString();
  }

  Future<void> _runAction(
    Future<CommunityModerationUserState> Function() action, {
    required String successMessage,
  }) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final updated = await action();
      if (!mounted) return;
      setState(() => _state = updated);
      AppSnackbar.showSuccess(context, successMessage);
    } catch (error) {
      if (!mounted) return;
      AppSnackbar.showError(context, _friendlyError(error));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _issueWarning() async {
    final reason = await _showReasonDialog(
      context: context,
      title: 'Issue Warning',
      hint: 'Enter warning reason',
      required: true,
    );
    if (reason == null || reason.trim().isEmpty) return;

    await _runAction(
      () => widget.repository.issueWarning(
        userId: widget.targetUserId,
        reason: reason.trim(),
        reportId: widget.report.id,
      ),
      successMessage: 'Warning issued',
    );
  }

  Future<void> _applyMute() async {
    final input = await _showDurationReasonDialog(
      context: context,
      title: 'Apply Mute',
      hint: 'Reason for mute',
      initialHours: 24,
    );
    if (input == null) return;

    await _runAction(
      () => widget.repository.applyMute(
        userId: widget.targetUserId,
        durationHours: input.hours,
        reason: input.reason,
        reportId: widget.report.id,
      ),
      successMessage: 'Mute applied',
    );
  }

  Future<void> _applySuspension() async {
    final input = await _showDurationReasonDialog(
      context: context,
      title: 'Apply Suspension',
      hint: 'Reason for suspension',
      initialHours: 24,
    );
    if (input == null) return;

    await _runAction(
      () => widget.repository.applySuspension(
        userId: widget.targetUserId,
        durationHours: input.hours,
        reason: input.reason,
        reportId: widget.report.id,
      ),
      successMessage: 'Suspension applied',
    );
  }

  Future<void> _applyRestrictions() async {
    final input = await _showRestrictionDialog(context);
    if (input == null) return;

    await _runAction(
      () => widget.repository.applyRestrictions(
        userId: widget.targetUserId,
        postingHours: input.postingHours,
        commentingHours: input.commentingHours,
        reason: input.reason,
        reportId: widget.report.id,
      ),
      successMessage: 'Restrictions updated',
    );
  }

  Future<void> _clearRestrictions() async {
    final reason = await _showReasonDialog(
      context: context,
      title: 'Clear Restrictions',
      hint: 'Reason for clearing',
      required: true,
    );
    if (reason == null || reason.trim().isEmpty) return;

    await _runAction(
      () => widget.repository.clearRestrictions(
        userId: widget.targetUserId,
        reason: reason.trim(),
        reportId: widget.report.id,
      ),
      successMessage: 'Restrictions cleared',
    );
  }

  String _formatTime(DateTime? value) {
    if (value == null) return '—';
    return value.toLocal().toString();
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 14,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderMuted,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'User Actions',
              style: AppTypography.custom(
                color: AppColors.textPrimary,
                size: 16,
                weight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            if (_loading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary500,
                  ),
                ),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  _error!,
                  style: AppTypography.custom(
                    color: AppColors.error500,
                    size: 12,
                    weight: FontWeight.w500,
                  ),
                ),
              )
            else if (state != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.bgElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.bestLabel,
                      style: AppTypography.custom(
                        color: AppColors.textPrimary,
                        size: 13,
                        weight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      state.email,
                      style: AppTypography.custom(
                        color: AppColors.textMuted,
                        size: 11,
                        weight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Warnings: ${state.communityWarnCount}',
                      style: AppTypography.custom(
                        color: AppColors.textSecondary,
                        size: 11,
                        weight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Muted until: ${_formatTime(state.communityMutedUntil)}',
                      style: AppTypography.custom(
                        color: AppColors.textSecondary,
                        size: 11,
                        weight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Suspended until: ${_formatTime(state.communitySuspendedUntil)}',
                      style: AppTypography.custom(
                        color: AppColors.textSecondary,
                        size: 11,
                        weight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Post restricted until: ${_formatTime(state.communityPostingRestrictedUntil)}',
                      style: AppTypography.custom(
                        color: AppColors.textSecondary,
                        size: 11,
                        weight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Comment restricted until: ${_formatTime(state.communityCommentingRestrictedUntil)}',
                      style: AppTypography.custom(
                        color: AppColors.textSecondary,
                        size: 11,
                        weight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: _busy ? null : _issueWarning,
                    child: const Text('Warn'),
                  ),
                  ElevatedButton(
                    onPressed: _busy ? null : _applyMute,
                    child: const Text('Mute'),
                  ),
                  if (widget.canEscalate)
                    ElevatedButton(
                      onPressed: _busy ? null : _applySuspension,
                      child: const Text('Suspend'),
                    ),
                  if (widget.canEscalate)
                    OutlinedButton(
                      onPressed: _busy ? null : _applyRestrictions,
                      child: const Text('Restrict'),
                    ),
                  if (widget.canEscalate)
                    OutlinedButton(
                      onPressed: _busy ? null : _clearRestrictions,
                      child: const Text('Clear'),
                    ),
                ],
              ),
              if (!widget.canEscalate) ...[
                const SizedBox(height: 8),
                Text(
                  'You can issue warnings and mutes. Suspension/restrictions are limited to community admins and governance.',
                  style: AppTypography.custom(
                    color: AppColors.textMuted,
                    size: 11,
                    weight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ],
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _DurationReasonInput {
  const _DurationReasonInput({
    required this.hours,
    required this.reason,
  });

  final int hours;
  final String reason;
}

class _RestrictionInput {
  const _RestrictionInput({
    required this.postingHours,
    required this.commentingHours,
    required this.reason,
  });

  final int? postingHours;
  final int? commentingHours;
  final String reason;
}

Future<String?> _showReasonDialog({
  required BuildContext context,
  required String title,
  required String hint,
  required bool required,
}) async {
  final controller = TextEditingController();
  String? inlineError;

  final value = await showDialog<String>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(hintText: hint),
                ),
                if (inlineError != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    inlineError!,
                    style: AppTypography.custom(
                      color: AppColors.error500,
                      size: 12,
                      weight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final text = controller.text.trim();
                  if (required && text.length < 3) {
                    setState(() {
                      inlineError = 'Reason must be at least 3 characters.';
                    });
                    return;
                  }
                  Navigator.of(context).pop(text);
                },
                child: const Text('Continue'),
              ),
            ],
          );
        },
      );
    },
  );

  controller.dispose();
  return value;
}

Future<_DurationReasonInput?> _showDurationReasonDialog({
  required BuildContext context,
  required String title,
  required String hint,
  required int initialHours,
}) async {
  final hoursController = TextEditingController(text: '$initialHours');
  final reasonController = TextEditingController();
  String? inlineError;

  final value = await showDialog<_DurationReasonInput>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: hoursController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Duration (hours)',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: reasonController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(hintText: hint),
                ),
                if (inlineError != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    inlineError!,
                    style: AppTypography.custom(
                      color: AppColors.error500,
                      size: 12,
                      weight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final hours = int.tryParse(hoursController.text.trim());
                  final reason = reasonController.text.trim();
                  if (hours == null || hours <= 0) {
                    setState(() => inlineError = 'Duration must be above 0.');
                    return;
                  }
                  if (reason.length < 3) {
                    setState(
                      () =>
                          inlineError = 'Reason must be at least 3 characters.',
                    );
                    return;
                  }
                  Navigator.of(context).pop(
                    _DurationReasonInput(hours: hours, reason: reason),
                  );
                },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      );
    },
  );

  hoursController.dispose();
  reasonController.dispose();
  return value;
}

Future<_RestrictionInput?> _showRestrictionDialog(BuildContext context) async {
  final postHoursController = TextEditingController();
  final commentHoursController = TextEditingController();
  final reasonController = TextEditingController();
  String? inlineError;

  final value = await showDialog<_RestrictionInput>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Apply Restrictions'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: postHoursController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Posting hours (optional)',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: commentHoursController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Commenting hours (optional)',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: reasonController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Reason for restrictions',
                    ),
                  ),
                  if (inlineError != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      inlineError!,
                      style: AppTypography.custom(
                        color: AppColors.error500,
                        size: 12,
                        weight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final posting = int.tryParse(postHoursController.text.trim());
                  final commenting =
                      int.tryParse(commentHoursController.text.trim());
                  final reason = reasonController.text.trim();

                  final validPosting = posting != null && posting > 0;
                  final validCommenting = commenting != null && commenting > 0;
                  if (!validPosting && !validCommenting) {
                    setState(() {
                      inlineError =
                          'Provide posting or commenting duration above 0.';
                    });
                    return;
                  }
                  if (reason.length < 3) {
                    setState(() {
                      inlineError = 'Reason must be at least 3 characters.';
                    });
                    return;
                  }

                  Navigator.of(context).pop(
                    _RestrictionInput(
                      postingHours: validPosting ? posting : null,
                      commentingHours: validCommenting ? commenting : null,
                      reason: reason,
                    ),
                  );
                },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      );
    },
  );

  postHoursController.dispose();
  commentHoursController.dispose();
  reasonController.dispose();
  return value;
}
