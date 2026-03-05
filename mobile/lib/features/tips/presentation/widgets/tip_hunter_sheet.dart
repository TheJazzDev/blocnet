import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/tips/data/models/tip_models.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/engagement/tips_store.dart';
import 'package:blocnet/services/users/user_profile_store.dart';
import 'package:blocnet/shared/widgets/app_avatar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TipHunterSheet extends StatefulWidget {
  const TipHunterSheet({
    super.key,
    required this.recipient,
    required this.contextType,
    this.contextId,
  });

  final TipRecipient recipient;
  final String contextType;
  final String? contextId;

  static Future<void> show(
    BuildContext context, {
    required TipRecipient recipient,
    required String contextType,
    String? contextId,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.92,
        child: TipHunterSheet(
          recipient: recipient,
          contextType: contextType,
          contextId: contextId,
        ),
      ),
    );
  }

  @override
  State<TipHunterSheet> createState() => _TipHunterSheetState();
}

class _TipHunterSheetState extends State<TipHunterSheet> {
  static final RegExp _amountPattern = RegExp(r'^\d+(\.\d+)?$');
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthStore>();
      final store = context.read<TipsStore>();
      store.ensureUserScope(auth.userId);
      store.loadOverview(force: true);
      store.loadSentHistory(force: true, limit: 100);
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthStore>();
    final store = context.read<TipsStore>();
    final userProfileStore = context.read<UserProfileStore>();
    final amount = _amountController.text.trim();
    final note = _noteController.text.trim();
    final recipient = widget.recipient;
    final overview = store.overview;

    if (auth.userId != null && auth.userId == recipient.userId) {
      setState(() => _error = 'You cannot tip yourself.');
      return;
    }

    if (!_amountPattern.hasMatch(amount)) {
      setState(() => _error = 'Enter a valid amount.');
      return;
    }

    final currency = overview?.activeCurrency;
    if (currency != null) {
      final decimals = currency.decimals;
      final parts = amount.split('.');
      final fraction = parts.length > 1 ? parts[1] : '';
      if (fraction.length > decimals) {
        setState(
          () => _error = 'Amount supports up to $decimals decimal places.',
        );
        return;
      }
    }

    setState(() => _error = null);
    try {
      await store.sendTip(
        amount: amount,
        toUserId: recipient.userId,
        currencyCode: currency?.code,
        note: note.isEmpty ? null : note,
        contextType: widget.contextType,
        contextId: widget.contextId,
        idempotencyKey: 'tip-${DateTime.now().microsecondsSinceEpoch}',
      );
      await userProfileStore.refreshAll();
      if (!mounted) return;
      _amountController.clear();
      _noteController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tip sent to ${recipient.label}'),
          backgroundColor: AppColors.successColor,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = store.describeError(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgBase,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Consumer<TipsStore>(
          builder: (context, store, _) {
            final overview = store.overview;
            final active = overview?.activeCurrency;
            final balance = active == null
                ? null
                : overview?.findBalance(active.code)?.balance;
            final feePolicy = active?.feePolicy;
            final feePct = feePolicy == null
                ? 0
                : (feePolicy.feeBps / 100).toStringAsFixed(2);

            final history = store.sentHistory
                .where((row) => row.recipient.id == widget.recipient.userId)
                .toList(growable: false);
            final allSentHistory = store.sentHistory;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 8),
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderMuted,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                  child: Row(
                    children: [
                      Text(
                        'Tip Hunter',
                        style: AppTypography.custom(
                          color: AppColors.textPrimary,
                          size: 17,
                          weight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close_rounded,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      4,
                      16,
                      20 + MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _RecipientHeader(recipient: widget.recipient),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.bgSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your balance: ${balance ?? '0'} ${active?.symbol ?? ''}',
                                style: AppTypography.custom(
                                  color: AppColors.textSecondary,
                                  size: 12,
                                  weight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Fee: $feePct% (${feePolicy?.senderPaysFee == false ? 'hunter pays' : 'sender pays'})',
                                style: AppTypography.custom(
                                  color: AppColors.textMuted,
                                  size: 11.5,
                                  weight: FontWeight.w400,
                                ),
                              ),
                              if (feePolicy?.minTip != null) ...[
                                const SizedBox(height: 3),
                                Text(
                                  'Minimum tip: ${feePolicy!.minTip} ${active?.symbol ?? ''}',
                                  style: AppTypography.custom(
                                    color: AppColors.textMuted,
                                    size: 11.5,
                                    weight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Amount (${active?.symbol ?? 'BNP'})',
                          style: AppTypography.custom(
                            color: AppColors.textSecondary,
                            size: 12,
                            weight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: AppTypography.custom(
                            color: AppColors.textPrimary,
                            size: 14,
                            weight: FontWeight.w500,
                          ),
                          decoration: _fieldDecoration('0.0'),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Note (optional)',
                          style: AppTypography.custom(
                            color: AppColors.textSecondary,
                            size: 12,
                            weight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _noteController,
                          maxLines: 2,
                          style: AppTypography.custom(
                            color: AppColors.textPrimary,
                            size: 13,
                            weight: FontWeight.w500,
                          ),
                          decoration: _fieldDecoration('Thanks for the alpha.'),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            _error!,
                            style: AppTypography.custom(
                              color: AppColors.error500,
                              size: 12,
                              weight: FontWeight.w500,
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                                store.isSending || store.isLoadingOverview
                                    ? null
                                    : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary500,
                              foregroundColor: Colors.black,
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: store.isSending
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      color: AppColors.bgBase,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'Send Tip',
                                    style: AppTypography.custom(
                                      color: Colors.black,
                                      size: 13,
                                      weight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Recent Tips To This Hunter',
                          style: AppTypography.custom(
                            color: AppColors.textPrimary,
                            size: 13,
                            weight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (store.isLoadingSentHistory && history.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: CircularProgressIndicator(
                                color: AppColors.primary500,
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        else if (history.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.bgSurface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.borderSubtle),
                            ),
                            child: Text(
                              'No tip history yet for this hunter.',
                              style: AppTypography.custom(
                                color: AppColors.textMuted,
                                size: 12,
                                weight: FontWeight.w500,
                              ),
                            ),
                          )
                        else
                          ...history.take(8).map(
                                (row) => _TipHistoryRow(item: row),
                              ),
                        const SizedBox(height: 14),
                        Text(
                          'All Tips Sent',
                          style: AppTypography.custom(
                            color: AppColors.textPrimary,
                            size: 13,
                            weight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (store.isLoadingSentHistory &&
                            allSentHistory.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: CircularProgressIndicator(
                                color: AppColors.primary500,
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        else if (allSentHistory.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.bgSurface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.borderSubtle),
                            ),
                            child: Text(
                              'No sent tips yet.',
                              style: AppTypography.custom(
                                color: AppColors.textMuted,
                                size: 12,
                                weight: FontWeight.w500,
                              ),
                            ),
                          )
                        else
                          ...allSentHistory.take(8).map(
                                (row) => _TipHistoryRow(item: row),
                              ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTypography.custom(
        color: AppColors.textFaint,
        size: 12,
        weight: FontWeight.w400,
      ),
      filled: true,
      fillColor: AppColors.bgSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.borderSubtle),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.borderSubtle),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primary500),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    );
  }
}

class _RecipientHeader extends StatelessWidget {
  const _RecipientHeader({required this.recipient});

  final TipRecipient recipient;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = recipient.avatarUrl?.trim() ?? '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          AppAvatar(
            radius: 18,
            imageUrl: avatarUrl,
            fallback: Icon(Icons.person, color: AppColors.textMuted, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipient.label,
                  style: AppTypography.custom(
                    color: AppColors.textPrimary,
                    size: 13.5,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  recipient.isHunterHint ? 'Hunter' : 'Hunter candidate',
                  style: AppTypography.custom(
                    color: AppColors.textMuted,
                    size: 11.5,
                    weight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary500.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: AppColors.primary500.withValues(alpha: 0.45),
              ),
            ),
            child: Text(
              'TIP',
              style: AppTypography.custom(
                color: AppColors.primary400,
                size: 10,
                weight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TipHistoryRow extends StatelessWidget {
  const _TipHistoryRow({required this.item});

  final TipTransaction item;

  @override
  Widget build(BuildContext context) {
    final outgoing = item.direction == 'sent';
    final amountColor =
        outgoing ? const Color(0xFFF87171) : AppColors.successColor;
    final prefix = outgoing ? '-' : '+';
    final date = item.createdAt;
    final dateLabel =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.note?.trim().isNotEmpty == true
                      ? item.note!.trim()
                      : 'Tip transfer',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.custom(
                    color: AppColors.textPrimary,
                    size: 12.5,
                    weight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  dateLabel,
                  style: AppTypography.custom(
                    color: AppColors.textMuted,
                    size: 11,
                    weight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$prefix${item.amount} ${item.currency.symbol}',
            style: AppTypography.custom(
              color: amountColor,
              size: 12.5,
              weight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
