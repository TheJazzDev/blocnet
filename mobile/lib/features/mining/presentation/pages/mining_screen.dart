import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/mining/data/mine_cycle_phase.dart';
import 'package:blocnet/features/mining/data/mine_local_cache.dart';
import 'package:blocnet/features/mining/presentation/widgets/cycle/mine_second_ticker.dart';
import 'package:blocnet/features/mining/presentation/widgets/help/mine_explainer.dart';
import 'package:blocnet/features/mining/presentation/widgets/mine_load_error.dart';
import 'package:blocnet/features/mining/presentation/widgets/mine_tab_body.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/engagement/mining_store.dart';
import 'package:blocnet/services/notifications/notification_settings_store.dart';
import 'package:blocnet/services/wallet/wallet_store.dart';
import 'package:blocnet/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The Mine tab. The header (`Mine`, history, help) is the shared app bar;
/// see `MineHeaderActions`.
class MiningScreen extends StatefulWidget {
  const MiningScreen({super.key, this.localCache = const MineLocalCache()});

  final MineLocalCache localCache;

  @override
  State<MiningScreen> createState() => _MiningScreenState();
}

class _MiningScreenState extends State<MiningScreen> {
  String? _lastShownError;
  Set<String> _dismissedExpired = const {};
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Coming back after hours away must not show a stale cycle (F-55); only
    // while this tab is on screen.
    _lifecycle = AppLifecycleListener(onResume: _onAppResumed);
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  Future<void> _boot() async {
    if (!mounted) return;
    final store = context.read<MiningStore>();
    final settings = context.read<NotificationSettingsStore>();
    final userId = context.read<AuthStore>().userId;
    store.refreshAll();
    settings.fetchInitialOnce(userId: userId);
    MineExplainer.instance.autoOpenOnce(widget.localCache);
    final dismissed = await widget.localCache.dismissedExpiredCycles();
    if (!mounted) return;
    setState(() => _dismissedExpired = {..._dismissedExpired, ...dismissed});
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _onAppResumed() {
    if (!mounted || !isMiningTabVisible(context)) return;
    context.read<MiningStore>().loadSnapshot(force: true);
  }

  /// A failed action, or a failed refresh while data is already on screen.
  /// A failed first load gets the full couldn't-load state instead.
  String? _feedbackError(MiningStore store) {
    final action = store.actionError;
    if (action != null && action.isNotEmpty) return action;
    if (store.snapshot == null) return null;
    final refresh = store.snapshotError;
    return (refresh != null && refresh.isNotEmpty) ? refresh : null;
  }

  void _surfaceError(MiningStore store) {
    final error = _feedbackError(store);
    if (error == null) {
      _lastShownError = null;
      return;
    }
    if (error == _lastShownError) return;
    _lastShownError = error;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppSnackbar.showError(context, error);
    });
  }

  Future<void> _onStart(MiningStore store) async {
    try {
      await store.startMining();
    } catch (_) {
      // Surfaced through store.actionError.
    }
  }

  Future<void> _onClaim(MiningStore store) async {
    final wallet = context.read<WalletStore>();
    try {
      final result = await store.claimMining();
      if (result == null || !result.isClaimed) return;
      // The receipt is drawn from store.lastClaimResult; the wallet catch-up
      // is best effort.
      await wallet.refreshAll();
    } catch (_) {
      // Surfaced through store.actionError.
    }
  }

  Future<void> _dismissExpired(String sessionId) async {
    setState(() => _dismissedExpired = {..._dismissedExpired, sessionId});
    context.read<MiningStore>().clearForfeitNotice();
    await widget.localCache.dismissExpiredCycle(sessionId);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MiningStore>(
      builder: (context, store, _) {
        _surfaceError(store);
        final snapshot = store.snapshot;
        final phase = MineCycleClock.resolve(
          snapshot: snapshot,
          isLoading: store.isLoadingSnapshot,
          loadError: store.snapshotError,
          now: store.serverNow(),
        );

        final Widget child;
        if (phase == MineCyclePhase.loadError) {
          child = MineLoadError(
            lastBalance: store.lastKnownBalance,
            isRetrying: store.isLoadingSnapshot,
            onRetry: () => store.loadSnapshot(force: true),
          );
        } else if (snapshot == null) {
          child = const Padding(
            padding: EdgeInsets.all(AppSpace.xxxl),
            child: Center(
              child: SizedBox.square(
                dimension: AppIcon.lg,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        } else {
          child = MineTabBody(
            store: store,
            snapshot: snapshot,
            phase: phase,
            dismissedExpired: _dismissedExpired,
            onStart: () => _onStart(store),
            onClaim: () => _onClaim(store),
            onDismissExpired: _dismissExpired,
          );
        }

        return RefreshIndicator(
          color: AppColors.primary500,
          backgroundColor: AppColors.bgSurface,
          onRefresh: store.refreshAll,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [child],
          ),
        );
      },
    );
  }
}
