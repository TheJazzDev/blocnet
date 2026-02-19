part of '../wallet_screen.dart';

class _ActionRow extends StatelessWidget {
  const _ActionRow();

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'This feature is coming soon!',
          style: GoogleFonts.inter(),
        ),
        backgroundColor: AppColors.bgSurface,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final address = context.watch<WalletStore>().snapshot?.walletAddress;

    return Row(
      children: [
        _ActionButton(
          icon: Icons.arrow_upward_rounded,
          label: 'Send',
          onTap: () => _showComingSoon(context),
        ),
        const SizedBox(width: 10),
        _ActionButton(
          icon: Icons.arrow_downward_rounded,
          label: 'Receive',
          onTap: () {
            if (address == null || address.isEmpty) {
              _showComingSoon(context);
              return;
            }
            Clipboard.setData(ClipboardData(text: address));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Wallet address copied',
                  style: GoogleFonts.inter(),
                ),
                backgroundColor: AppColors.bgSurface,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
        const SizedBox(width: 10),
        _ActionButton(
          icon: Icons.swap_horiz_rounded,
          label: 'Swap',
          onTap: () => _showComingSoon(context),
        ),
        const SizedBox(width: 10),
        _ActionButton(
          icon: Icons.add_rounded,
          label: 'Buy',
          onTap: () => _showComingSoon(context),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.teal500.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.teal400, size: 17),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotifyButton extends StatelessWidget {
  const _NotifyButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "We'll notify you when BNT goes live!",
                style: GoogleFonts.inter(),
              ),
              backgroundColor: AppColors.bgSurface,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.teal500, AppColors.primary500],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.notifications_outlined,
                color: AppColors.bgBase,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Notify Me at Launch',
                style: GoogleFonts.inter(
                  color: AppColors.bgBase,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
