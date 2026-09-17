import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/mining/data/mine_cycle_view.dart';
import 'package:blocnet/features/mining/presentation/mine_palette.dart';
import 'package:blocnet/services/notifications/notification_settings_store.dart';
import 'package:blocnet/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The push type the switch controls (backend `NotificationType`).
const String mineCycleReadyType = 'mining_cycle_ready';

/// `Notify me when it's ready` with a switch bound to the member's per-type
/// override for [mineCycleReadyType].
class MineNotifyRow extends StatelessWidget {
  const MineNotifyRow({super.key});

  Future<void> _toggle(
    BuildContext context,
    NotificationSettingsStore store,
    bool enabled,
  ) async {
    final ok = await store.setTypeEnabled(mineCycleReadyType, enabled);
    if (!context.mounted || ok) return;
    AppSnackbar.showError(
      context,
      store.lastError ?? 'Unable to save notification settings right now.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<NotificationSettingsStore>();
    final value = store.isTypeEnabled(mineCycleReadyType) ?? false;
    final master = store.preferences?.masterEnabled ?? true;
    // Nothing to bind until preferences load; a master switch that is off
    // wins over any override, so the row cannot turn it on from here.
    final enabled = store.hasLoaded && master && !store.isSaving;

    return Container(
      margin: const EdgeInsets.only(top: AppSpace.lg),
      padding: const EdgeInsets.only(top: AppSpace.sm),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: MinePalette.edge)),
      ),
      child: MergeSemantics(
        child: SizedBox(
          height: 44,
          child: Row(
            children: [
              Icon(
                Icons.notifications_active_outlined,
                size: AppIcon.md,
                color: MinePalette.accentSoft,
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Text(
                  MineCycleView.notifyLabel,
                  style: AppText.label(MinePalette.text, weight: AppText.bold),
                ),
              ),
              Switch(
                key: const ValueKey('mine-notify-switch'),
                value: value,
                onChanged:
                    enabled ? (next) => _toggle(context, store, next) : null,
                activeColor: Colors.white,
                activeTrackColor: MinePalette.accent,
                inactiveThumbColor: MinePalette.muted,
                inactiveTrackColor: MinePalette.raised,
                trackOutlineColor:
                    const WidgetStatePropertyAll(MinePalette.strongEdge),
                materialTapTargetSize: MaterialTapTargetSize.padded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
