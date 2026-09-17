import 'package:blocnet/app/config.dart';
import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/system_alerts/data/models/system_alert_model.dart';
import 'package:blocnet/services/api/api_client.dart';
import 'package:flutter/material.dart';

const systemAlertsLoadErrorText =
    "Couldn't load system alerts. Pull down to try again.";
const systemAlertsSessionErrorText =
    'Your session has expired. Sign in again.';

/// True when [error] means the session is gone. The backend sends raw
/// exception text, so the known message is matched as well as the code.
bool isSessionExpiredError(ApiException error) =>
    error.statusCode == 401 ||
    error.message.toLowerCase().contains('invalid or expired token');

/// A plain sentence for [error]; never the backend's raw message.
String systemAlertsErrorText(Object error) {
  if (error is ApiException && isSessionExpiredError(error)) {
    return systemAlertsSessionErrorText;
  }
  return systemAlertsLoadErrorText;
}

/// `14:05` today, `9/16 14:05` otherwise.
String formatAlertTimestamp(DateTime value, {DateTime? now}) {
  final local = value.toLocal();
  final today = now ?? DateTime.now();
  final sameDay = local.year == today.year &&
      local.month == today.month &&
      local.day == today.day;
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  if (sameDay) return '$hh:$mm';
  return '${local.month}/${local.day} $hh:$mm';
}

Color alertStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'error':
      return AppColors.tagWarning;
    case 'warning':
      return AppColors.warning500;
    case 'success':
      return AppColors.successColor;
    default:
      return AppColors.textMuted;
  }
}

IconData alertStatusIcon(String status) {
  switch (status.toLowerCase()) {
    case 'error':
      return Icons.error_outline_rounded;
    case 'warning':
      return Icons.warning_amber_rounded;
    case 'success':
      return Icons.check_circle_outline_rounded;
    default:
      return Icons.info_outline_rounded;
  }
}

/// Admin console page that best matches [alert], with the alert as query.
Uri buildAdminConsoleUri(SystemAlertModel alert) {
  final parsedBase = Uri.tryParse(AppConfig.adminConsoleBaseUrl.trim());
  final base = parsedBase != null && parsedBase.host.isNotEmpty
      ? parsedBase
      : Uri.parse('https://console.blocnet.app');

  final resourceType = alert.resourceType.toLowerCase();
  final action = alert.action.toLowerCase();
  final query = <String, String>{'alertId': alert.id};
  final resourceId = alert.resourceId?.trim();
  if (resourceId != null && resourceId.isNotEmpty) {
    query['q'] = resourceId;
  }

  var targetPath = '/audit-log';
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
  return base.replace(
    path: '$normalizedBasePath$targetPath',
    queryParameters: query,
  );
}
