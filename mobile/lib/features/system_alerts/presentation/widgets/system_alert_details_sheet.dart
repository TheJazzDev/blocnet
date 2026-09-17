import 'dart:convert';

import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/system_alerts/data/models/system_alert_model.dart';
import 'package:blocnet/features/system_alerts/presentation/utils/system_alert_format.dart';
import 'package:blocnet/features/system_alerts/presentation/widgets/system_alert_detail_parts.dart';
import 'package:blocnet/features/system_alerts/presentation/widgets/system_alert_ui.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:blocnet/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Every field of [alert], with copy, and a link to the admin console.
Future<void> showSystemAlertDetails(
  BuildContext context,
  SystemAlertModel alert,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.bgSurface,
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
    builder: (_) => SystemAlertDetailsSheet(alert: alert),
  );
}

class SystemAlertDetailsSheet extends StatelessWidget {
  const SystemAlertDetailsSheet({super.key, required this.alert});

  final SystemAlertModel alert;

  Future<void> _copy(BuildContext context, String label, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    AppSnackbar.showSuccess(context, '$label copied');
  }

  Future<void> _openConsole(BuildContext context, Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      AppSnackbar.showError(context, "Couldn't open the admin console.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final metadata = const JsonEncoder.withIndent('  ').convert(alert.metadata);
    final consoleUri = buildAdminConsoleUri(alert);
    final color = alertStatusColor(alert.status);
    final fields = <(String, String)>[
      ('Alert ID', alert.id),
      ('Source', alert.source),
      ('Provider', alert.provider),
      ('Action', alert.action),
      if (alert.summary.isNotEmpty) ('Summary', alert.summary),
      if (alert.resourceType.isNotEmpty) ('Resource', alert.resourceType),
      if ((alert.resourceId ?? '').isNotEmpty)
        ('Resource ID', alert.resourceId!),
      if ((alert.actorId ?? '').isNotEmpty) ('Actor ID', alert.actorId!),
      if ((alert.actorEmail ?? '').isNotEmpty) ('Actor', alert.actorEmail!),
    ];

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(
            AppSpace.lg, AppSpace.md, AppSpace.lg, AppSpace.xxl),
        children: [
          const SheetHandle(),
          const SizedBox(height: AppSpace.lg),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Alert details',
                  style: AppText.subtitle(AppColors.textPrimary,
                      weight: AppText.bold),
                ),
              ),
              AppPill.caps(label: alert.status, color: color),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          DetailFieldsCard(
            fields: fields,
            onCopy: (label, value) => _copy(context, label, value),
          ),
          const SizedBox(height: AppSpace.lg),
          Text('METADATA', style: alertCaps(AppColors.textFaint)),
          const SizedBox(height: AppSpace.sm),
          MetadataBlock(text: metadata),
          const SizedBox(height: AppSpace.lg),
          AlertButton(
            label: 'Open in admin console',
            icon: Icons.open_in_browser_rounded,
            filled: true,
            onPressed: () => _openConsole(context, consoleUri),
          ),
          const SizedBox(height: AppSpace.sm),
          Row(
            children: [
              Expanded(
                child: AlertButton(
                  label: 'Copy metadata',
                  icon: Icons.copy_rounded,
                  onPressed: () => _copy(context, 'Metadata', metadata),
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: AlertButton(
                  label: 'Copy link',
                  icon: Icons.link_rounded,
                  onPressed: () =>
                      _copy(context, 'Console link', consoleUri.toString()),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            'The admin console works best on a tablet or desktop.',
            style: AppText.label(AppColors.textFaint),
          ),
        ],
      ),
    );
  }
}
