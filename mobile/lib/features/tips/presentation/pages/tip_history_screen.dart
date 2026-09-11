import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/features/tips/presentation/models/tip_history_mode.dart';
import 'package:blocnet/features/tips/presentation/widgets/tip_history_list_item.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/engagement/tips_store.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthStore>();
      final store = context.read<TipsStore>();
      store.ensureUserScope(auth.userId);
      if (widget.mode == TipHistoryMode.received) {
        store.loadReceivedHistory(force: true, limit: 100);
      } else {
        store.loadSentHistory(force: true, limit: 100);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: CustomAppBar(
        title: widget.mode == TipHistoryMode.received
            ? 'Received Tip History'
            : 'Tip History',
        backButton: true,
        showSearch: false,
        showFilter: false,
      ),
      body: Consumer<TipsStore>(
        builder: (context, store, _) {
          final isReceived = widget.mode == TipHistoryMode.received;
          final rows = isReceived ? store.receivedHistory : store.sentHistory;
          final total =
              isReceived ? store.receivedHistoryTotal : store.sentHistoryTotal;
          final isLoading = isReceived
              ? store.isLoadingReceivedHistory
              : store.isLoadingSentHistory;
          final hasError = (store.lastError?.trim().isNotEmpty ?? false);

          return RefreshIndicator(
            color: AppColors.primary500,
            backgroundColor: AppColors.bgSurface,
            onRefresh: () => isReceived
                ? store.loadReceivedHistory(force: true, limit: 100)
                : store.loadSentHistory(force: true, limit: 100),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Text(
                  isReceived
                      ? 'All tips you have received from supporters.'
                      : 'All tips you have sent to hunters.',
                  style: AppTypography.custom(
                    color: AppColors.textMuted,
                    size: 12,
                    weight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isReceived ? '$total tips received' : '$total tips sent',
                  style: AppTypography.custom(
                    color: AppColors.textFaint,
                    size: 11,
                    weight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                if (isLoading && rows.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: AppColors.primary500,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  )
                else if (rows.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasError
                              ? 'Unable to load tip history right now.'
                              : isReceived
                                  ? 'No tips received yet.'
                                  : 'No tips sent yet.',
                          style: AppTypography.custom(
                            color: AppColors.textMuted,
                            size: 12,
                            weight: FontWeight.w500,
                          ),
                        ),
                        if (hasError) ...[
                          const SizedBox(height: 6),
                          Text(
                            "Couldn't load tips. ${store.lastError}",
                            style: AppTypography.custom(
                              color: AppColors.warning500,
                              size: 11,
                              weight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                else
                  ...rows.map(
                    (row) => TipHistoryListItem(
                      row: row,
                      mode: widget.mode,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
