import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/features/tips/data/models/tip_models.dart';
import 'package:blocnet/services/auth_store.dart';
import 'package:blocnet/services/tips_store.dart';
import 'package:blocnet/shared/utils/get_timestamp.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum TipHistoryMode { sent, received }

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
                            'Tip sync warning: ${store.lastError}',
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
                    (row) => _TipHistoryListItem(
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

class _TipHistoryListItem extends StatelessWidget {
  const _TipHistoryListItem({
    required this.row,
    required this.mode,
  });

  final TipTransaction row;
  final TipHistoryMode mode;

  @override
  Widget build(BuildContext context) {
    final isReceived = mode == TipHistoryMode.received;
    final symbol = row.currency.symbol.trim().isEmpty
        ? row.currency.code
        : row.currency.symbol;
    final counterparty = isReceived ? _senderLabel(row) : _recipientLabel(row);
    final note = row.note?.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: isReceived
                  ? AppColors.successColor.withValues(alpha: 0.12)
                  : AppColors.error500.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isReceived ? Icons.south_west_rounded : Icons.north_east_rounded,
              size: 16,
              color: isReceived ? AppColors.successColor : AppColors.error500,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isReceived ? 'From $counterparty' : 'To $counterparty',
                  style: AppTypography.custom(
                    color: AppColors.textPrimary,
                    size: 12.5,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  note != null && note.isNotEmpty
                      ? note
                      : _contextLabel(
                          row.contextType,
                          isReceived: isReceived,
                        ),
                  style: AppTypography.custom(
                    color: AppColors.textFaint,
                    size: 10.5,
                    weight: FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  getTimeStamp(row.createdAt),
                  style: AppTypography.custom(
                    color: AppColors.textFaint,
                    size: 10,
                    weight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isReceived
                    ? '+${row.amount} $symbol'
                    : '-${row.totalDebit} $symbol',
                style: AppTypography.custom(
                  color:
                      isReceived ? AppColors.successColor : AppColors.error500,
                  size: 12,
                  weight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                isReceived
                    ? 'Tip ${row.amount}'
                    : 'Tip ${row.amount} · Fee ${row.fee}',
                style: AppTypography.custom(
                  color: AppColors.textFaint,
                  size: 10,
                  weight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _recipientLabel(TipTransaction row) {
  final displayName = row.recipient.displayName?.trim();
  if (displayName != null && displayName.isNotEmpty) {
    return displayName;
  }

  final username = row.recipient.username?.trim();
  if (username != null && username.isNotEmpty) {
    return username.startsWith('@') ? username : '@$username';
  }

  return row.recipient.id.isNotEmpty ? row.recipient.id : 'Hunter';
}

String _contextLabel(
  String? contextType, {
  required bool isReceived,
}) {
  final value = contextType?.trim() ?? '';
  if (value.isEmpty) {
    return isReceived ? 'Tip received' : 'Tip sent';
  }
  return value.replaceAll('_', ' ');
}

String _senderLabel(TipTransaction row) {
  final displayName = row.sender.displayName?.trim();
  if (displayName != null && displayName.isNotEmpty) {
    return displayName;
  }

  final username = row.sender.username?.trim();
  if (username != null && username.isNotEmpty) {
    return username.startsWith('@') ? username : '@$username';
  }

  return row.sender.id.isNotEmpty ? row.sender.id : 'User';
}
