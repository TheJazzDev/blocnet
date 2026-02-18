part of '../wallet_screen.dart';

class _WalletAddressTile extends StatelessWidget {
  const _WalletAddressTile();

  static const String _placeholder = 'BNT-XXXX-XXXX-XXXX-XXXX';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(const ClipboardData(text: _placeholder));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Address copied to clipboard',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: AppColors.bgSurface,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.bgElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                size: 17,
                color: AppColors.teal400,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your BNT Address',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _placeholder,
                    style: GoogleFonts.inter(
                      color: AppColors.textFaint,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.bgElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: [
                  Icon(Icons.copy_rounded, size: 12, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    'Copy',
                    style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DisclaimerText extends StatelessWidget {
  const _DisclaimerText();

  @override
  Widget build(BuildContext context) {
    return Text(
      "BNT is Blocnet's native utility token. It is not a security or financial instrument. "
      'All wallet features are under active development and subject to change.',
      textAlign: TextAlign.center,
      style: GoogleFonts.inter(
        color: AppColors.textFaint,
        fontSize: 10,
        height: 1.6,
      ),
    );
  }
}
