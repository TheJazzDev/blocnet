import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/system_alerts/data/models/system_alert_model.dart';
import 'package:blocnet/features/system_alerts/presentation/utils/system_alert_format.dart';
import 'package:blocnet/features/system_alerts/presentation/widgets/system_alert_ui.dart';
import 'package:flutter/material.dart';

/// One alert as a flat card row: status icon, summary, source · provider,
/// status pill, time.
class SystemAlertTile extends StatelessWidget {
  const SystemAlertTile({
    super.key,
    required this.alert,
    required this.onTap,
    this.now,
  });

  final SystemAlertModel alert;
  final VoidCallback onTap;

  /// Clock override for tests.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final color = alertStatusColor(alert.status);
    final title = alert.summary.isEmpty ? alert.action : alert.summary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.md,
        child: Ink(
          decoration: alertCardDecoration(),
          padding: AppSpace.card,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AlertIconSquare(
                icon: alertStatusIcon(alert.status),
                color: color,
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _titleRow(title),
                    const SizedBox(height: AppSpace.hair),
                    Text(
                      '${alert.source} · ${alert.provider} · ${alert.action}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.label(AppColors.textMuted),
                    ),
                    const SizedBox(height: AppSpace.sm),
                    AlertPill(label: alert.status, color: color),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _titleRow(String title) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppText.body(AppColors.textPrimary, weight: AppText.bold),
          ),
        ),
        const SizedBox(width: AppSpace.sm),
        Text(
          formatAlertTimestamp(alert.createdAt, now: now),
          style: AppText.caption(AppColors.textFaint),
        ),
      ],
    );
  }
}
