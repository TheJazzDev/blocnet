import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/features/tips/data/models/tip_models.dart';
import 'package:blocnet/services/auth_store.dart';
import 'package:blocnet/services/tips_store.dart';
import 'package:blocnet/shared/utils/get_timestamp.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TipHistoryScreen extends StatefulWidget {
  const TipHistoryScreen({super.key});

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
      store.loadSentHistory(force: true, limit: 200);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: const CustomAppBar(
        title: 'Tip History',
        backButton: true,
        showSearch: false,
        showFilter: false,
      ),
      body: Consumer<TipsStore>(
        builder: (context, store, _) {
          final rows = store.sentHistory;
          final hasError = (store.lastError?.trim().isNotEmpty ?? false);

          return RefreshIndicator(
            color: AppColors.primary500,
            backgroundColor: AppColors.bgSurface,
            onRefresh: () => store.loadSentHistory(force: true, limit: 200),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Text(
                  'All tips you have sent to hunters.',
                  style: AppTypography.custom(
                    color: AppColors.textMuted,
                    size: 12,
                    weight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${store.sentHistoryTotal} tips sent',
                  style: AppTypography.custom(
                    color: AppColors.textFaint,
                    size: 11,
                    weight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                if (store.isLoadingSentHistory && rows.isEmpty)
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
                  ...rows.map((row) => _TipHistoryListItem(row: row)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TipHistoryListItem extends StatelessWidget {
  const _TipHistoryListItem({required this.row});

  final TipTransaction row;

  @override
  Widget build(BuildContext context) {
    final symbol = row.currency.symbol.trim().isEmpty
        ? row.currency.code
        : row.currency.symbol;
    final recipient = _recipientLabel(row);
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
              color: AppColors.error500.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.north_east_rounded,
              size: 16,
              color: AppColors.error500,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'To $recipient',
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
                      : _contextLabel(row.contextType),
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
                '-${row.totalDebit} $symbol',
                style: AppTypography.custom(
                  color: AppColors.error500,
                  size: 12,
                  weight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                'Tip ${row.amount} · Fee ${row.fee}',
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

String _contextLabel(String? contextType) {
  final value = contextType?.trim() ?? '';
  if (value.isEmpty) {
    return 'Tip sent';
  }
  return value.replaceAll('_', ' ');
}
