import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/community/data/models/community_moderation_models.dart';
import 'package:blocnet/features/community/data/repositories/community_moderation_api_repository.dart';
import 'package:blocnet/services/api/api_client.dart';
import 'package:blocnet/shared/utils/get_timestamp.dart';
import 'package:flutter/material.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  final _repository = CommunityModerationApiRepository();
  final _scrollController = ScrollController();

  List<CommunityModerationReport> _reports = [];
  bool _isLoading = false;
  bool _hasMore = true;
  String? _errorMessage;
  int _offset = 0;
  final int _limit = 20;

  @override
  void initState() {
    super.initState();
    _loadReports();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      if (!_isLoading && _hasMore) {
        _loadMore();
      }
    }
  }

  Future<void> _loadReports() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _offset = 0;
    });

    try {
      final page = await _repository.fetchReports(
        limit: _limit,
        offset: 0,
      );

      if (!mounted) return;

      setState(() {
        _reports = page.reports;
        _hasMore = page.reports.length >= _limit;
        _offset = page.reports.length;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load reports';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final page = await _repository.fetchReports(
        limit: _limit,
        offset: _offset,
      );

      if (!mounted) return;

      setState(() {
        _reports.addAll(page.reports);
        _hasMore = page.reports.length >= _limit;
        _offset = _reports.length;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Map<String, int> _calculateStatistics() {
    final total = _reports.length;
    final open = _reports.where((r) => r.status == CommunityReportStatus.open).length;
    final resolved = _reports.where((r) => r.status == CommunityReportStatus.resolved).length;
    final dismissed = _reports.where((r) => r.status == CommunityReportStatus.dismissed).length;

    return {
      'total': total,
      'open': open,
      'resolved': resolved,
      'dismissed': dismissed,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        title: Text(
          'My Reports',
          style: AppTypography.custom(
            size: 18,
            weight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        color: AppColors.primary500,
        backgroundColor: AppColors.bgSurface,
        onRefresh: _loadReports,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null && _reports.isEmpty) {
      return _buildError();
    }

    if (_isLoading && _reports.isEmpty) {
      return Center(
        child: CircularProgressIndicator(
          color: AppColors.primary500,
          strokeWidth: 2,
        ),
      );
    }

    if (_reports.isEmpty) {
      return _buildEmpty();
    }

    final stats = _calculateStatistics();

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _reports.length + (_hasMore ? 1 : 0) + 1, // +1 for stats header
      itemBuilder: (context, index) {
        // Statistics header
        if (index == 0) {
          return _ReportStatistics(stats: stats);
        }

        // Adjust index for reports (accounting for stats header)
        final reportIndex = index - 1;

        if (reportIndex >= _reports.length) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.primary500,
                strokeWidth: 2,
              ),
            ),
          );
        }

        final report = _reports[reportIndex];
        return _ReportCard(report: report);
      },
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.flag_outlined,
                size: 36,
                color: AppColors.textFaint,
              ),
              const SizedBox(height: 10),
              Text(
                'No Reports Yet',
                style: AppTypography.custom(
                  color: AppColors.textSecondary,
                  size: 15,
                  weight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Your submitted reports will appear here',
                textAlign: TextAlign.center,
                style: AppTypography.custom(
                  color: AppColors.textMuted,
                  size: 12,
                  weight: FontWeight.w400,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 36,
                color: AppColors.error500,
              ),
              const SizedBox(height: 10),
              Text(
                'Error Loading Reports',
                style: AppTypography.custom(
                  color: AppColors.textSecondary,
                  size: 15,
                  weight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _errorMessage ?? 'Something went wrong',
                textAlign: TextAlign.center,
                style: AppTypography.custom(
                  color: AppColors.textMuted,
                  size: 12,
                  weight: FontWeight.w400,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadReports,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary500,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  'Retry',
                  style: AppTypography.custom(
                    size: 13,
                    weight: FontWeight.w600,
                    color: Colors.black,
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

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report});

  final CommunityModerationReport report;

  Color _getStatusColor() {
    switch (report.status) {
      case CommunityReportStatus.open:
        return AppColors.warning500;
      case CommunityReportStatus.resolved:
        return Colors.green;
      case CommunityReportStatus.dismissed:
        return AppColors.textMuted;
    }
  }

  IconData _getStatusIcon() {
    switch (report.status) {
      case CommunityReportStatus.open:
        return Icons.pending_outlined;
      case CommunityReportStatus.resolved:
        return Icons.check_circle_outline;
      case CommunityReportStatus.dismissed:
        return Icons.cancel_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.bgSurface,
            AppColors.bgSurface.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.borderSubtle.withValues(alpha: 0.75),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with type and status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary400.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    report.targetType.label,
                    style: AppTypography.custom(
                      size: 11,
                      weight: FontWeight.w600,
                      color: AppColors.primary400,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(
                  _getStatusIcon(),
                  size: 16,
                  color: statusColor,
                ),
                const SizedBox(width: 4),
                Text(
                  report.status.label,
                  style: AppTypography.custom(
                    size: 12,
                    weight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Reason
            Text(
              report.reason,
              style: AppTypography.custom(
                size: 14,
                weight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),

            if (report.details != null && report.details!.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                report.details!,
                style: AppTypography.custom(
                  size: 13,
                  weight: FontWeight.w400,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: 12),

            // Timestamp
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 12,
                  color: AppColors.textFaint,
                ),
                const SizedBox(width: 4),
                Text(
                  'Reported ${getTimeStamp(report.createdAt)}',
                  style: AppTypography.custom(
                    size: 11,
                    weight: FontWeight.w400,
                    color: AppColors.textFaint,
                  ),
                ),
              ],
            ),

            // Resolution info if resolved/dismissed
            if (report.status != CommunityReportStatus.open) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.admin_panel_settings_outlined,
                          size: 14,
                          color: statusColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          report.status == CommunityReportStatus.resolved
                              ? 'Resolved'
                              : 'Dismissed',
                          style: AppTypography.custom(
                            size: 12,
                            weight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                        if (report.reviewedAt != null) ...[
                          const SizedBox(width: 4),
                          Text(
                            '• ${getTimeStamp(report.reviewedAt!)}',
                            style: AppTypography.custom(
                              size: 11,
                              weight: FontWeight.w400,
                              color: AppColors.textFaint,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (report.resolutionNote != null &&
                        report.resolutionNote!.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        report.resolutionNote!,
                        style: AppTypography.custom(
                          size: 12,
                          weight: FontWeight.w400,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


class _ReportStatistics extends StatelessWidget {
  const _ReportStatistics({required this.stats});

  final Map<String, int> stats;

  @override
  Widget build(BuildContext context) {
    final total = stats["total"] ?? 0;
    final open = stats["open"] ?? 0;
    final resolved = stats["resolved"] ?? 0;
    final dismissed = stats["dismissed"] ?? 0;
    final reviewedCount = resolved + dismissed;
    final reviewedRate = total > 0 ? (reviewedCount / total * 100).toStringAsFixed(0) : "0";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary400.withValues(alpha: 0.1),
            AppColors.primary400.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary400.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_outlined, color: AppColors.primary400, size: 20),
              const SizedBox(width: 8),
              Text("Report Statistics", style: AppTypography.custom(size: 15, weight: FontWeight.w600, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _StatCard(label: "Total", value: total.toString(), color: AppColors.primary400, icon: Icons.flag_outlined)),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(label: "Pending", value: open.toString(), color: AppColors.warning500, icon: Icons.pending_outlined)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _StatCard(label: "Resolved", value: resolved.toString(), color: Colors.green, icon: Icons.check_circle_outline)),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(label: "Dismissed", value: dismissed.toString(), color: AppColors.textMuted, icon: Icons.cancel_outlined)),
            ],
          ),
          if (total > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.bgSurface, borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.speed, size: 16, color: AppColors.primary400),
                  const SizedBox(width: 6),
                  Text("Review Rate: ", style: AppTypography.custom(size: 12, weight: FontWeight.w500, color: AppColors.textSecondary)),
                  Text("$reviewedRate%", style: AppTypography.custom(size: 12, weight: FontWeight.w700, color: AppColors.primary400)),
                  Text(" ($reviewedCount/$total reviewed)", style: AppTypography.custom(size: 11, weight: FontWeight.w400, color: AppColors.textMuted)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.color, required this.icon});
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.bgSurface, borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(value, style: AppTypography.custom(size: 22, weight: FontWeight.w700, color: color)),
          const SizedBox(height: 2),
          Text(label, style: AppTypography.custom(size: 11, weight: FontWeight.w500, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
