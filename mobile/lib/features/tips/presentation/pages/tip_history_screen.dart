import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/profile/presentation/pages/public_profile_screen.dart';
import 'package:blocnet/features/profile/presentation/widgets/common/profile_inline_state.dart';
import 'package:blocnet/features/profile/presentation/widgets/section_label.dart';
import 'package:blocnet/features/projects/data/models/admin_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/detail_dialogs.dart';
import 'package:blocnet/features/tips/data/models/tip_models.dart';
import 'package:blocnet/features/tips/presentation/models/tip_history_mode.dart';
import 'package:blocnet/features/tips/presentation/widgets/tip_history_list_item.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/engagement/tips_store.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

export 'package:blocnet/features/tips/presentation/models/tip_history_mode.dart';

class TipHistoryScreen extends StatefulWidget {
  const TipHistoryScreen({
    super.key,
    this.mode = TipHistoryMode.sent,
  });

  final TipHistoryMode mode;

  @override
  State<TipHistoryScreen> createState() => _TipHistoryScreenState();
}

class _TipHistoryScreenState extends State<TipHistoryScreen> {
  bool get _isReceived => widget.mode == TipHistoryMode.received;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context
          .read<TipsStore>()
          .ensureUserScope(context.read<AuthStore>().userId);
      _load();
    });
  }

  Future<void> _load() {
    final store = context.read<TipsStore>();
    return _isReceived
        ? store.loadReceivedHistory(force: true, limit: 100)
        : store.loadSentHistory(force: true, limit: 100);
  }

  /// A tip on an update opens that update; a tip from a profile opens the
  /// other person's profile.
  VoidCallback? _openerFor(TipTransaction row) {
    final contextId = row.contextId?.trim() ?? '';
    if (row.contextType == 'update' && contextId.isNotEmpty) {
      return () => showUpdateDetailsDialog(context, contextId);
    }
    final party = _isReceived ? row.sender : row.recipient;
    if (party.id.trim().isEmpty) return null;
    return () => PublicProfileScreen.showSheet(
          context,
          Admin(
            id: party.id,
            name: party.displayName ?? '',
            username: party.username ?? '',
            imageUrl: party.avatarUrl ?? '',
            followers: 0,
            currentLevel: party.currentLevel,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<TipsStore>();
    final rows = _isReceived ? store.receivedHistory : store.sentHistory;
    final total =
        _isReceived ? store.receivedHistoryTotal : store.sentHistoryTotal;
    final isLoading = _isReceived
        ? store.isLoadingReceivedHistory
        : store.isLoadingSentHistory;
    final failed = store.lastError?.trim().isNotEmpty ?? false;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: CustomAppBar(
        title: _isReceived ? 'Tips Received' : 'Tip History',
        backButton: true,
        showSearch: false,
        showFilter: false,
      ),
      body: RefreshIndicator(
        color: AppColors.primary500,
        backgroundColor: AppColors.bgSurface,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
              AppSpace.lg, AppSpace.lg, AppSpace.lg, AppSpace.xl),
          children: [
            SectionLabel(
              _isReceived ? 'Received' : 'Sent',
              icon: _isReceived
                  ? Icons.savings_outlined
                  : Icons.volunteer_activism_outlined,
              trailing: Text(
                '$total',
                style:
                    AppText.caption(AppColors.textFaint, weight: AppText.bold),
              ),
            ),
            AppSpace.gapSm,
            if (isLoading && rows.isEmpty)
              const SkeletonList(items: 4, itemHeight: 56)
            else if (rows.isEmpty)
              AppRowGroup(
                children: [
                  failed
                      ? ProfileInlineState(
                          icon: Icons.cloud_off_rounded,
                          title: 'Could not load tips',
                          actionLabel: 'Retry',
                          onAction: _load,
                        )
                      : ProfileInlineState(
                          icon: Icons.volunteer_activism_outlined,
                          title: _isReceived
                              ? 'No tips received yet'
                              : 'No tips sent yet',
                        ),
                ],
              )
            else
              AppRowGroup(
                children: [
                  for (final row in rows)
                    TipHistoryListItem(
                      key: ValueKey(row.id),
                      row: row,
                      mode: widget.mode,
                      onTap: _openerFor(row),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
