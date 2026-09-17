import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/features/system_alerts/data/models/system_alert_model.dart';
import 'package:blocnet/features/system_alerts/data/repositories/system_alerts_api_repository.dart';
import 'package:blocnet/features/system_alerts/presentation/utils/system_alert_format.dart';
import 'package:blocnet/features/system_alerts/presentation/widgets/system_alert_detail_parts.dart';
import 'package:blocnet/features/system_alerts/presentation/widgets/system_alert_details_sheet.dart';
import 'package:blocnet/features/system_alerts/presentation/widgets/system_alert_tile.dart';
import 'package:blocnet/features/system_alerts/presentation/widgets/system_alert_ui.dart';
import 'package:blocnet/services/api/api_client.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAlerts());
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
    } catch (error) {
      if (!mounted) return;
      final message = systemAlertsErrorText(error);
      setState(() {
        _error = message;
        _isSessionExpired =
            error is ApiException && isSessionExpiredError(error);
      });
      AppSnackbar.showError(context, message);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authStore = context.watch<AuthStore>();
    final canView = authStore.isOwner || authStore.isDev;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: CustomAppBar(
        title: 'System Alerts',
        backButton: true,
        showSearch: false,
        showFilter: false,
        actions: [
          if (canView)
            IconButton(
              tooltip: 'Refresh',
              onPressed:
                  _isRefreshing ? null : () => _loadAlerts(refreshing: true),
              icon: Icon(
                Icons.refresh_rounded,
                size: AppIcon.lg,
                color: AppColors.textMuted,
              ),
            ),
        ],
      ),
      body: _body(canView, authStore),
    );
  }

  Widget _body(bool canView, AuthStore authStore) {
    if (!canView) {
      return const Padding(
        padding: AppSpace.allLg,
        child: AlertMessageCard(
          icon: Icons.lock_outline_rounded,
          title: 'Owners and devs only',
          message: 'System alerts are limited to the owner and dev roles.',
        ),
      );
    }
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: AppColors.primary400,
          strokeWidth: 2,
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.primary400,
      backgroundColor: AppColors.bgSurface,
      onRefresh: () => _loadAlerts(refreshing: true),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
            AppSpace.lg, AppSpace.md, AppSpace.lg, AppSpace.xxl),
        itemCount: _alerts.isEmpty ? 1 : _alerts.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpace.sm),
        itemBuilder: (context, index) {
          if (_alerts.isEmpty) return _emptyCard(authStore);
          final alert = _alerts[index];
          return SystemAlertTile(
            alert: alert,
            onTap: () => showSystemAlertDetails(context, alert),
          );
        },
      ),
    );
  }

  Widget _emptyCard(AuthStore authStore) {
    final error = _error;
    if (error == null) {
      return const AlertMessageCard(
        icon: Icons.check_circle_outline_rounded,
        title: 'No system alerts',
        message: 'New alerts show up here.',
      );
    }
    return AlertMessageCard(
      icon: Icons.error_outline_rounded,
      title: _isSessionExpired ? 'Session expired' : "Couldn't load alerts",
      message: error,
      action: _isSessionExpired
          ? AlertButton(
              label: 'Sign in again',
              filled: true,
              onPressed: authStore.signOut,
            )
          : null,
    );
  }
}
