import 'dart:async';

import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/community/data/models/community_moderation_models.dart';
import 'package:blocnet/features/community/data/repositories/community_moderation_api_repository.dart';
import 'package:blocnet/features/community/presentation/widgets/community_content_moderation_sheet.dart';
import 'package:blocnet/features/moderation/presentation/widgets/common/mod_app_bar.dart';
import 'package:blocnet/features/moderation/presentation/widgets/common/mod_input_dialogs.dart';
import 'package:blocnet/features/moderation/presentation/widgets/common/mod_queue_body.dart';
import 'package:blocnet/features/moderation/presentation/widgets/reports/member_actions_sheet.dart';
import 'package:blocnet/features/moderation/presentation/widgets/reports/report_card.dart';
import 'package:blocnet/features/moderation/presentation/widgets/reports/report_filter_bar.dart';
import 'package:blocnet/features/moderation/presentation/widgets/reports/reports_pagination_bar.dart';
import 'package:blocnet/services/api/api_client.dart';
import 'package:blocnet/services/api/api_error.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Community reports, twenty to a page, with search and filters.
class ReportsQueueScreen extends StatefulWidget {
  const ReportsQueueScreen({this.apiClient, super.key});

  /// Injectable for tests.
  final ApiClient? apiClient;

  @override
  State<ReportsQueueScreen> createState() => _ReportsQueueScreenState();
}

class _ReportsQueueScreenState extends State<ReportsQueueScreen> {
  static const int _pageSize = 20;
  static const Duration _searchDelay = Duration(milliseconds: 350);

  late final CommunityModerationApiRepository _repository =
      CommunityModerationApiRepository(apiClient: widget.apiClient);
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _lastQuery = '';

  CommunityReportStatus? _statusFilter;
  CommunityReportTargetType? _targetTypeFilter;

  bool _isLoading = false;

  /// A load was asked for while one was running; run it when that ends so
  /// the list matches the latest search and filters.
  bool _reloadQueued = false;
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
    _searchDebounce?.cancel();
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  String get _query => _searchController.text.trim();

  void _handleSearchChanged() {
    final query = _query;
    // Cursor moves and selection changes also notify; only text matters.
    if (query == _lastQuery) return;
    _searchDebounce?.cancel();
    if (query.length == 1) return;
    _searchDebounce = Timer(_searchDelay, () {
      _lastQuery = query;
      _loadReports(resetOffset: true);
    });
  }

  Future<void> _loadReports({bool resetOffset = false}) async {
    if (resetOffset) _offset = 0;
    if (_isLoading) {
      _reloadQueued = true;
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final page = await _repository.fetchReports(
        limit: _pageSize,
        offset: _offset,
        q: _query.isEmpty ? null : _query,
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
      setState(() => _error = _describe(error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
    if (mounted && _reloadQueued) {
      _reloadQueued = false;
      await _loadReports();
    }
  }

  String _describe(Object error) =>
      describeApiError(error, fallback: 'Reports could not be loaded.');

  bool get _canGoPrev => _offset > 0 && !_isLoading;
  bool get _canGoNext => _offset + _pageSize < _total && !_isLoading;

  Future<void> _reviewReport(
    CommunityModerationReport report,
    CommunityReportStatus status,
  ) async {
    final resolving = status == CommunityReportStatus.resolved;
    final note = await showModReasonDialog(
      context,
      title: resolving ? 'Resolve report' : 'Dismiss report',
      hint: resolving ? 'What did you do?' : 'Why dismiss it?',
      required: false,
      confirmLabel: resolving ? 'Resolve' : 'Dismiss',
    );
    if (note == null || !mounted) return;

    setState(() => _isReviewing = true);
    try {
      await _repository.reviewReport(
        reportId: report.id,
        status: status,
        note: note.isEmpty ? null : note,
      );
      if (!mounted) return;
      AppSnackbar.showSuccess(
        context,
        resolving ? 'Report resolved' : 'Report dismissed',
      );
      await _loadReports();
    } catch (error) {
      if (!mounted) return;
      AppSnackbar.showError(context, _describe(error));
    } finally {
      if (mounted) setState(() => _isReviewing = false);
    }
  }

  Future<void> _openMemberActions(
    CommunityModerationReport report,
    String targetUserId,
  ) {
    final auth = context.read<AuthStore>();
    return showMemberActionsSheet(
      context,
      repository: _repository,
      report: report,
      targetUserId: targetUserId,
      canEscalate:
          auth.isOwner || auth.isDev || auth.isAdmin || auth.isCommunityAdmin,
    );
  }

  Future<void> _moderateReportTarget(CommunityModerationReport report) async {
    final isComment =
        report.targetType == CommunityReportTargetType.communityComment;
    final auth = context.read<AuthStore>();
    final decision = await showCommunityContentModerationSheet(
      context,
      targetLabel: isComment ? 'comment' : 'post',
      canArchive: auth.isCommunityAdmin,
    );
    if (decision == null || !mounted) return;

    setState(() => _isReviewing = true);
    try {
      if (isComment) {
        await _repository.moderateCommunityCommentStatus(
          commentId: report.targetId,
          status: decision.status,
          reason: decision.reason,
        );
      } else {
        await _repository.moderateCommunityPostStatus(
          postId: report.targetId,
          status: decision.status,
          reason: decision.reason,
        );
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
      AppSnackbar.showError(context, _describe(error));
    } finally {
      if (mounted) setState(() => _isReviewing = false);
    }
  }

  void _changePage(int delta) {
    setState(() => _offset = (_offset + delta).clamp(0, _total));
    _loadReports();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: const ModAppBar(title: 'Reports'),
      body: Column(
        children: [
          ReportFilterBar(
            searchController: _searchController,
            statusFilter: _statusFilter,
            targetTypeFilter: _targetTypeFilter,
            isLoading: _isLoading,
            onStatusChanged: (value) {
              setState(() => _statusFilter = value);
              _loadReports(resetOffset: true);
            },
            onTargetTypeChanged: (value) {
              setState(() => _targetTypeFilter = value);
              _loadReports(resetOffset: true);
            },
          ),
          Expanded(
            child: ModQueueBody(
              isLoading: _isLoading,
              error: _error,
              itemCount: _reports.length,
              itemBuilder: (context, index) => _card(_reports[index]),
              onRefresh: _loadReports,
              errorTitle: 'Reports did not load',
              emptyIcon: Icons.flag_outlined,
              emptyTitle: 'No reports',
              emptyMessage: 'Nothing matches these filters.',
            ),
          ),
          ReportsPaginationBar(
            from: _reports.isEmpty ? 0 : _offset + 1,
            to: (_offset + _reports.length).clamp(0, _total),
            total: _total,
            onPrev: _canGoPrev ? () => _changePage(-_pageSize) : null,
            onNext: _canGoNext ? () => _changePage(_pageSize) : null,
          ),
        ],
      ),
    );
  }

  Widget _card(CommunityModerationReport report) {
    final isContent =
        report.targetType == CommunityReportTargetType.communityPost ||
            report.targetType == CommunityReportTargetType.communityComment;
    final targetUserId = report.targetUserId?.trim() ?? '';
    return ReportCard(
      report: report,
      reviewing: _isReviewing,
      onResolve: report.isOpen
          ? () => _reviewReport(report, CommunityReportStatus.resolved)
          : null,
      onDismiss: report.isOpen
          ? () => _reviewReport(report, CommunityReportStatus.dismissed)
          : null,
      onContentActions: isContent ? () => _moderateReportTarget(report) : null,
      onUserActions: targetUserId.isEmpty
          ? null
          : () => _openMemberActions(report, targetUserId),
    );
  }
}
