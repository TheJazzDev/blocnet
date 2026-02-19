import 'package:blocnet/app/theme.dart';
import 'package:blocnet/services/wallet_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

part 'wallet/wallet_screen_sections.part.dart';
part 'wallet/wallet_screen_actions.part.dart';
part 'wallet/wallet_screen_info.part.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final walletStore = context.read<WalletStore>();
      walletStore.loadWalletSummary(force: true);
      walletStore.loadTransactions(force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final walletStore = context.watch<WalletStore>();
    final isLoading =
        walletStore.isLoadingSummary && walletStore.snapshot == null;
    final error = walletStore.lastError;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              SizedBox(height: 20),
              _BalanceCard(),
              SizedBox(height: 16),
              _ActionRow(),
              SizedBox(height: 24),
              _SectionLabel('Wallet Address'),
              SizedBox(height: 8),
              _WalletAddressTile(),
              SizedBox(height: 24),
              _SectionLabel("What's Coming"),
              SizedBox(height: 8),
              _FeatureTile(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Fund Wallet',
                description:
                    'Deposit funds and convert to BNT at the live exchange rate.',
              ),
              _FeatureTile(
                icon: Icons.card_giftcard_outlined,
                title: 'Tip Hunters',
                description:
                    'Send BNT directly to hunters whose updates you find valuable.',
              ),
              _FeatureTile(
                icon: Icons.emoji_events_outlined,
                title: 'Earn Rewards',
                description:
                    'Get BNT for quality engagement, consistent reading, and referrals.',
              ),
              _FeatureTile(
                icon: Icons.swap_horiz_rounded,
                title: 'Transfer & Withdraw',
                description:
                    'Send BNT to other users or withdraw to your external wallet.',
              ),
              SizedBox(height: 24),
              _SectionLabel('Recent Transactions'),
              SizedBox(height: 8),
              _TransactionsList(),
              SizedBox(height: 24),
              _NotifyButton(),
              SizedBox(height: 16),
              _DisclaimerText(),
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
      floatingActionButton: isLoading
          ? null
          : FloatingActionButton.small(
              onPressed: walletStore.refreshAll,
              backgroundColor: AppColors.bgSurface,
              child:
                  Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            ),
      bottomNavigationBar: error == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  'Wallet sync warning: $error',
                  style: GoogleFonts.inter(
                    color: AppColors.textFaint,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
    );
  }
}
