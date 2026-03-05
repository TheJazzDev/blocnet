import 'dart:convert';

import 'package:blocnet/app/config.dart';
import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/projects/presentation/models/feed_view_mode.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/features/system_alerts/data/models/system_alert_model.dart';
import 'package:blocnet/features/system_alerts/data/repositories/system_alerts_api_repository.dart';
import 'package:blocnet/services/api/api_client.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/core/feed_view_mode_store.dart';
import 'package:blocnet/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SystemAlertsScreen extends StatefulWidget {
  const SystemAlertsScreen({super.key});

  @override
  State<SystemAlertsScreen> createState() => _SystemAlertsScreenState();
}

class _SystemAlertsScreenState extends State<SystemAlertsScreen> {
  final SystemAlertsApiRepository _repository = SystemAlertsApiRepository();
  final List<SystemAlertModel> _alerts = <SystemAlertModel>[];

  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAlerts();
    });
  }

  Future<void> _loadAlerts({bool refreshing = false}) async {
    if (!mounted) return;

    setState(() {
      _error = null;
      if (refreshing) {
        _isRefreshing = true;
      } else {
        _isLoading = true;
      }
    });

    try {
      final rows = await _repository.fetchSystemAlerts(
        limit: 80,
        offset: 0,
        status: 'all',
      );
      if (!mounted) return;
      setState(() {
        _alerts
          ..clear()
          ..addAll(rows);
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      final nextError = error.message;
      setState(() => _error = nextError);
      AppSnackbar.showError(context, nextError);
    } catch (_) {
      if (!mounted) return;
      const nextError = 'Unable to load system alerts right now.';
      setState(() => _error = nextError);
      AppSnackbar.showError(context, nextError);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  String _formatTimestamp(DateTime value) {
    final local = value.toLocal();
    final now = DateTime.now();
    final sameDay = local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    if (sameDay) return '$hh:$mm';
    return '${local.month}/${local.day} $hh:$mm';
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'error':
        return const Color(0xFFEF4444);
      case 'warning':
        return const Color(0xFFF59E0B);
      case 'success':
        return const Color(0xFF10B981);
      default:
        return AppColors.textMuted;
    }
  }

  Future<void> _copyText(String label, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    AppSnackbar.showSuccess(context, '$label copied');
  }

  Uri _buildAdminConsoleUri(SystemAlertModel alert) {
    final configuredBase = AppConfig.adminConsoleBaseUrl.trim();
    final parsedBase = Uri.tryParse(configuredBase);
    final base = parsedBase != null && parsedBase.host.isNotEmpty
        ? parsedBase
        : Uri.parse('https://console.blocnet.app');

    final resourceType = alert.resourceType.toLowerCase();
    final action = alert.action.toLowerCase();
    final query = <String, String>{
      'alertId': alert.id,
    };
    final resourceId = alert.resourceId?.trim();
    if (resourceId != null && resourceId.isNotEmpty) {
      query['q'] = resourceId;
    }

    String targetPath = '/audit-log';
    if (resourceType.contains('user') ||
        resourceType.contains('profile') ||
        resourceType.contains('member')) {
      targetPath = '/members';
    } else if (resourceType.contains('wallet') || action.contains('wallet')) {
      targetPath = '/wallet/users';
    } else if (action.contains('tip')) {
      targetPath = '/tips/transactions';
    } else if (action.contains('quest') || action.contains('badge')) {
      targetPath = '/quests';
    }

    final basePath = base.path.trim();
    final normalizedBasePath = basePath.isEmpty || basePath == '/'
        ? ''
        : basePath.endsWith('/')
            ? basePath.substring(0, basePath.length - 1)
            : basePath;
    final mergedPath = '$normalizedBasePath$targetPath';
    return base.replace(
      path: mergedPath,
      queryParameters: query,
    );
  }

  Future<void> _openAdminConsole(SystemAlertModel alert) async {
    final uri = _buildAdminConsoleUri(alert);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      AppSnackbar.showError(context, 'Unable to open admin console.');
    }
  }

  void _showAlertDetails(SystemAlertModel alert) {
    final metadata = const JsonEncoder.withIndent('  ').convert(alert.metadata);
    final adminUri = _buildAdminConsoleUri(alert);
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.bgSurface,
          title: Text(
            'Alert details',
            style: AppTypography.custom(
              color: AppColors.textPrimary,
              size: 16,
              weight: FontWeight.w700,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow('Alert ID', alert.id),
                _detailRow('Status', alert.status.toUpperCase(),
                    copyable: false),
                _detailRow('Source', alert.source),
                _detailRow('Provider', alert.provider),
                _detailRow('Action', alert.action),
                _detailRow('Summary', alert.summary),
                _detailRow('Resource', alert.resourceType),
                if (alert.resourceId != null)
                  _detailRow('Resource ID', alert.resourceId!),
                if ((alert.actorId ?? '').isNotEmpty)
                  _detailRow('Actor ID', alert.actorId!),
                if ((alert.actorEmail ?? '').isNotEmpty)
                  _detailRow('Actor', alert.actorEmail!),
                const SizedBox(height: 10),
                Text(
                  'Metadata',
                  style: AppTypography.custom(
                    color: AppColors.textPrimary,
                    size: 12,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.bgBase,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: SelectableText(
                    metadata,
                    style: AppTypography.custom(
                      color: AppColors.textMuted,
                      size: 11,
                      weight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _copyText('Metadata', metadata),
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: const Text('Copy Metadata'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _copyText('Console URL', adminUri.toString()),
                        icon: const Icon(Icons.link_rounded, size: 16),
                        label: const Text('Copy Console URL'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _openAdminConsole(alert),
                        icon:
                            const Icon(Icons.open_in_browser_rounded, size: 16),
                        label: const Text('Open in Admin Console'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Admin console is optimized for tablet/desktop browsers.',
                  style: AppTypography.custom(
                    color: AppColors.textFaint,
                    size: 11,
                    weight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(
    String label,
    String value, {
    bool copyable = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTypography.custom(
                  color: AppColors.textMuted,
                  size: 12,
                  weight: FontWeight.w500,
                ),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: AppTypography.custom(
                      color: AppColors.textPrimary,
                      size: 12,
                      weight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
          if (copyable) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: () => _copyText(label, value),
              child: Icon(
                Icons.copy_rounded,
                size: 16,
                color: AppColors.textFaint,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authStore = context.watch<AuthStore>();
    final viewMode = context.watch<FeedViewModeStore>().mode;
    final canView = authStore.isOwner || authStore.isDev;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: const CustomAppBar(
        title: 'System Alerts',
        backButton: true,
        showSearch: false,
        showFilter: false,
      ),
      body: !canView
          ? Center(
              child: Text(
                'Only owner/dev can access system alerts.',
                style: AppTypography.custom(
                  color: AppColors.textMuted,
                  size: 13,
                  weight: FontWeight.w500,
                ),
              ),
            )
          : _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () => _loadAlerts(refreshing: true),
                  child: _alerts.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 120),
                            Center(
                              child: Text(
                                _error ?? 'No system alerts yet.',
                                style: AppTypography.custom(
                                  color: AppColors.textMuted,
                                  size: 13,
                                  weight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          itemCount: _alerts.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 0),
                          itemBuilder: (context, index) {
                            final alert = _alerts[index];
                            final statusColor = _statusColor(alert.status);
                            final isLast = index == _alerts.length - 1;
                            return _SystemAlertRowWrapper(
                              mode: viewMode,
                              showDivider: !isLast,
                              child: _SystemAlertTile(
                                mode: viewMode,
                                alert: alert,
                                statusColor: statusColor,
                                timeLabel: _formatTimestamp(alert.createdAt),
                                onTap: () => _showAlertDetails(alert),
                              ),
                            );
                          },
                        ),
                ),
      floatingActionButton: canView
          ? FloatingActionButton.small(
              onPressed:
                  _isRefreshing ? null : () => _loadAlerts(refreshing: true),
              backgroundColor: AppColors.teal500,
              child: const Icon(Icons.refresh_rounded),
            )
          : null,
    );
  }
}

class _SystemAlertTile extends StatelessWidget {
  const _SystemAlertTile({
    required this.mode,
    required this.alert,
    required this.statusColor,
    required this.timeLabel,
    required this.onTap,
  });

  final FeedViewMode mode;
  final SystemAlertModel alert;
  final Color statusColor;
  final String timeLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          mode == FeedViewMode.card ? 14 : 0,
          12,
          mode == FeedViewMode.card ? 14 : 0,
          12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    alert.summary.isEmpty ? alert.action : alert.summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.custom(
                      color: AppColors.textPrimary,
                      size: 13,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  timeLabel,
                  style: AppTypography.custom(
                    color: AppColors.textFaint,
                    size: 11,
                    weight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${alert.source.toUpperCase()} • ${alert.provider.toUpperCase()} • ${alert.status.toUpperCase()}',
              style: AppTypography.custom(
                color: statusColor,
                size: 11,
                weight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              alert.action,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.custom(
                color: AppColors.textMuted,
                size: 11,
                weight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SystemAlertRowWrapper extends StatelessWidget {
  const _SystemAlertRowWrapper({
    required this.mode,
    required this.showDivider,
    required this.child,
  });

  final FeedViewMode mode;
  final bool showDivider;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (mode == FeedViewMode.card) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.borderSubtle,
          ),
        ),
        child: child,
      );
    }

    return Column(
      children: [
        child,
        if (showDivider)
          Divider(
            height: 1,
            color: AppColors.borderSubtle,
          ),
      ],
    );
  }
}
