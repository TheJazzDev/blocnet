import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/tips/data/models/tip_models.dart';
import 'package:blocnet/features/tips/presentation/widgets/tip_sheet/tip_form.dart';
import 'package:blocnet/features/tips/presentation/widgets/tip_sheet/tip_recent_list.dart';
import 'package:blocnet/features/tips/presentation/widgets/tip_sheet/tip_recipient_card.dart';
import 'package:blocnet/features/tips/presentation/widgets/tip_sheet/tip_sheet_copy.dart';
import 'package:blocnet/features/tips/presentation/widgets/tip_sheet/tip_sheet_styles.dart';
import 'package:blocnet/features/tips/presentation/widgets/tip_sheet/tip_stat_tiles.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/engagement/tips_store.dart';
import 'package:blocnet/services/users/user_profile_store.dart';
import 'package:blocnet/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Send a tip to a member (usually a hunter) from a post, update or profile.
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
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String? _error;

  /// One key per sheet. The sheet closes after a send, so a second tip
  /// always opens a new sheet with a new key.
  late final String _idempotencyKey =
      'tip-${DateTime.now().microsecondsSinceEpoch}';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final store = context.read<TipsStore>();
      store.ensureUserScope(context.read<AuthStore>().userId);
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
    final store = context.read<TipsStore>();
    final userProfileStore = context.read<UserProfileStore>();
    final amount = _amountController.text.trim();
    final note = _noteController.text.trim();
    final recipient = widget.recipient;
    final currency = store.overview?.activeCurrency;

    final invalid = validateTip(
      amount: amount,
      recipientId: recipient.userId,
      ownUserId: context.read<AuthStore>().userId,
      currency: currency,
    );
    setState(() => _error = invalid);
    if (invalid != null) return;

    try {
      await store.sendTip(
        amount: amount,
        toUserId: recipient.userId,
        currencyCode: currency?.code,
        note: note.isEmpty ? null : note,
        contextType: widget.contextType,
        contextId: widget.contextId,
        idempotencyKey: _idempotencyKey,
      );
    } catch (error) {
      if (mounted) setState(() => _error = tipErrorText(store, error));
      return;
    }
    await userProfileStore.refreshAll();
    if (!mounted) return;
    AppSnackbar.showSuccess(context, 'Tip sent to ${recipient.label}.');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgBase,
        borderRadius: AppRadius.sheet,
        border: Border(top: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            _header(context),
            Expanded(
              child: Consumer<TipsStore>(
                builder: (context, store, _) => _body(context, store),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.sm,
        AppSpace.xs,
        AppSpace.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Send a tip',
              style: AppText.subtitle(
                AppColors.textPrimary,
                weight: AppText.bold,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close_rounded, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, TipsStore store) {
    final overview = store.overview;
    final active = overview?.activeCurrency;
    final symbol = active?.symbol ?? 'BNP';
    final balance =
        active == null ? null : overview?.findBalance(active.code)?.balance;
    final policy = active?.feePolicy;
    final minimum = tipMinimumLabel(policy, symbol);
    final recent = store.sentHistory
        .where((row) => row.recipient.id == widget.recipient.userId)
        .toList(growable: false);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.xs,
        AppSpace.lg,
        AppSpace.xl + MediaQuery.viewInsetsOf(context).bottom,
      ),
      children: [
        TipRecipientCard(recipient: widget.recipient),
        const SizedBox(height: AppSpace.md),
        TipStatTiles(
          balance: overview == null
              ? (store.isLoadingOverview ? '—' : '0 $symbol')
              : '${balance ?? '0'} $symbol',
          fee: tipFeeLabel(policy),
          feeNote: [tipFeePayer(policy), if (minimum != null) minimum].join(' · '),
        ),
        const SizedBox(height: AppSpace.lg),
        TipForm(
          amountController: _amountController,
          noteController: _noteController,
          symbol: symbol,
          error: _error,
          isSending: store.isSending,
          onSend: store.isLoadingOverview ? null : _submit,
        ),
        const SizedBox(height: AppSpace.xl),
        const TipSectionLabel('Your tips to them', icon: Icons.history_rounded),
        const SizedBox(height: AppSpace.sm),
        TipRecentList(items: recent, isLoading: store.isLoadingSentHistory),
      ],
    );
  }
}
