import 'dart:convert';

import 'package:blocnet/app/config.dart';
import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/projects/presentation/models/feed_view_mode.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/features/system_alerts/data/models/system_alert_model.dart';
import 'package:blocnet/features/system_alerts/data/repositories/system_alerts_api_repository.dart';
import 'package:blocnet/services/api/api_client.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/core/feed_view_mode_store.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
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
  bool _isSessionExpired = false;

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
      _isSessionExpired = false;
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
      final nextError = _friendlyErrorMessage(error);
      setState(() {
        _error = nextError;
        _isSessionExpired = error.statusCode == 401;
      });
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

  // The backend surfaces raw exception text (e.g. NestJS's
  // `UnauthorizedException('Invalid or expired token')`) as the API error
  // message with no structured code to branch on. Pattern-match the one
  // known-bad case here so end users don't see a raw auth/backend string.
  // A more general fix belongs on the backend (structured error codes
  // instead of opaque messages) — out of scope for this mobile-only patch.
  String _friendlyErrorMessage(ApiException error) {
    final raw = error.message.trim();
    final isSessionExpired = error.statusCode == 401 ||
        raw.toLowerCase().contains('invalid or expired token');
    if (isSessionExpired) {
      return 'Your session has expired. Please sign in again.';
    }
    return raw.isEmpty ? 'Unable to load system alerts right now.' : raw;
  }

  Future<void> _signInAgain() async {
    await context.read<AuthStore>().signOut();
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
              size: AppText.subtitleSize,
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
                const SizedBox(height: AppSpace.md),
                Text(
                  'Metadata',
                  style: AppTypography.custom(
                    color: AppColors.textPrimary,
                    size: AppText.labelSize,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpace.sm),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpace.md),
                  decoration: BoxDecoration(
                    color: AppColors.bgBase,
                    borderRadius: BorderRadius.circular(AppRadius.mdValue),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: SelectableText(
                    metadata,
                    style: AppTypography.custom(
                      color: AppColors.textMuted,
                      size: AppText.captionSize,
                      weight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpace.sm),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _copyText('Metadata', metadata),
                        icon: const Icon(Icons.copy_rounded, size: AppIcon.sm),
                        label: const Text('Copy Metadata'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.sm),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _copyText('Console URL', adminUri.toString()),
                        icon: const Icon(Icons.link_rounded, size: AppIcon.sm),
                        label: const Text('Copy Console URL'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.sm),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _openAdminConsole(alert),
                        icon: const Icon(Icons.open_in_browser_rounded,
                            size: AppIcon.sm),
                        label: const Text('Open in Admin Console'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.sm),
                Text(
                  'Admin console is optimized for tablet/desktop browsers.',
                  style: AppTypography.custom(
                    color: AppColors.textFaint,
                    size: AppText.captionSize,
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
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTypography.custom(
                  color: AppColors.textMuted,
                  size: AppText.labelSize,
                  weight: FontWeight.w500,
                ),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: AppTypography.custom(
                      color: AppColors.textPrimary,
                      size: AppText.labelSize,
                      weight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
          if (copyable) ...[
            const SizedBox(width: AppSpace.sm),
            InkWell(
              onTap: () => _copyText(label, value),
              child: Icon(
                Icons.copy_rounded,
                size: AppIcon.sm,
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
                  size: AppText.labelSize,
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
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpace.xl),
                                child: Text(
                                  _error ?? 'No system alerts yet.',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.custom(
                                    color: AppColors.textMuted,
                                    size: AppText.labelSize,
                                    weight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            if (_isSessionExpired) ...[
                              const SizedBox(height: AppSpace.lg),
                              Center(
                                child: OutlinedButton(
                                  onPressed: _signInAgain,
                                  child: const Text('Sign In Again'),
                                ),
                              ),
                            ],
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(AppSpace.lg,
                              AppSpace.md, AppSpace.lg, AppSpace.xl),
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
      borderRadius: BorderRadius.circular(AppRadius.lgValue),
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
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Text(
                    alert.summary.isEmpty ? alert.action : alert.summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.custom(
                      color: AppColors.textPrimary,
                      size: AppText.labelSize,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Text(
                  timeLabel,
                  style: AppTypography.custom(
                    color: AppColors.textFaint,
                    size: AppText.captionSize,
                    weight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.sm),
            Text(
              '${alert.source.toUpperCase()} • ${alert.provider.toUpperCase()} • ${alert.status.toUpperCase()}',
              style: AppTypography.custom(
                color: statusColor,
                size: AppText.captionSize,
                weight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            Text(
              alert.action,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.custom(
                color: AppColors.textMuted,
                size: AppText.captionSize,
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
      return AppSurface.flush(
        radius: AppRadius.lg,
        margin: const EdgeInsets.only(bottom: AppSpace.sm),
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
