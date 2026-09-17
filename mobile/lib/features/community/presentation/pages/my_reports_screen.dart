import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/community/data/models/community_moderation_models.dart';
import 'package:blocnet/features/community/data/repositories/community_moderation_api_repository.dart';
import 'package:blocnet/features/community/presentation/widgets/reports/report_row.dart';
import 'package:blocnet/features/community/presentation/widgets/reports/reports_summary.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/services/api/api_error.dart';
import 'package:blocnet/shared/widgets/app_empty_state.dart';
import 'package:flutter/material.dart';

/// The reports the member has sent and what happened to each.
class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key, this.repository});

  final CommunityModerationApiRepository? repository;

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  static const int _pageSize = 20;

  late final CommunityModerationApiRepository _repository =
      widget.repository ?? CommunityModerationApiRepository();
  final _scroll = ScrollController();

  final List<CommunityModerationReport> _reports = [];
  CommunityReportCounts? _counts;
  int _total = 0;
  bool _isLoading = false;
  bool _loaded = false;
  String? _error;

  bool get _hasMore => _reports.length < _total;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    if (position.pixels >= position.maxScrollExtent - 200) _loadMore();
  }

  Future<void> _load() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final page = await _repository.fetchMyReports(limit: _pageSize);
      if (!mounted) return;
      setState(() {
        _reports
          ..clear()
          ..addAll(page.reports);
        _counts = page.counts;
        _total = page.total;
        _loaded = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = describeApiError(error, fallback: 'Could not load reports');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);
    try {
      final page = await _repository.fetchMyReports(
        limit: _pageSize,
        offset: _reports.length,
      );
      if (!mounted) return;
      setState(() {
        _reports.addAll(page.reports);
        _total = page.reports.isEmpty ? _reports.length : page.total;
      });
    } catch (_) {
      // The next scroll retries; the loaded reports stay.
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  CommunityReportCounts get _summary =>
      _counts ??
      CommunityReportCounts(
        open: _countOf(CommunityReportStatus.open),
        resolved: _countOf(CommunityReportStatus.resolved),
        dismissed: _countOf(CommunityReportStatus.dismissed),
      );

  int _countOf(CommunityReportStatus status) =>
      _reports.where((r) => r.status == status).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: const CustomAppBar(
        title: 'My reports',
        showSearch: false,
        showFilter: false,
        showNotificationBell: false,
        showSpaceSwitcher: false,
      ),
      body: RefreshIndicator(
        color: AppColors.primary400,
        backgroundColor: AppColors.bgSurface,
        onRefresh: _load,
        child: _body(),
      ),
    );
  }

  Widget _body() {
    if (_reports.isEmpty) {
      final Widget child;
      if (!_loaded && _error == null) {
        child = Padding(
          padding: const EdgeInsets.only(top: AppSpace.xxxl * 2),
          child: Center(
            child: CircularProgressIndicator(
              color: AppColors.primary400,
              strokeWidth: 2,
            ),
          ),
        );
      } else if (_error != null) {
        child = AppEmptyState.error(
          title: 'Couldn’t load your reports',
          message: _error,
          onAction: _load,
        );
      } else {
        child = const AppEmptyState(
          icon: Icons.flag_outlined,
          title: 'No reports yet',
          message: 'Reports you send from a post or comment show up here.',
        );
      }
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [child],
      );
    }

    return ListView.separated(
      controller: _scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.md,
        AppSpace.lg,
        MediaQuery.paddingOf(context).bottom + AppSpace.xl,
      ),
      itemCount: _reports.length + 1 + (_hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: AppSpace.md),
      itemBuilder: (context, index) {
        if (index == 0) return ReportsSummary(counts: _summary);
        final i = index - 1;
        if (i < _reports.length) return ReportRow(report: _reports[i]);
        return Padding(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Center(
            child: CircularProgressIndicator(
              color: AppColors.primary400,
              strokeWidth: 2,
            ),
          ),
        );
      },
    );
  }
}
