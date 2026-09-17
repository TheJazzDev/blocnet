part of '../main_screen.dart';

/// Shown once when the hunter role is granted. The primary action takes the
/// member straight into the space the role unlocked.
///
/// A flat bordered card, left-aligned, like every other dialog in the app.
class _HunterOnboardingDialog extends StatelessWidget {
  const _HunterOnboardingDialog();

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.primary500;
    // Black on the cyan hunter accent, white on the blue user accent.
    final onAccent =
        accent.computeLuminance() > 0.4 ? Colors.black : Colors.white;
    final hunterTint = AppColors.hunterAccent;

    return Dialog(
      elevation: 0,
      backgroundColor: AppColors.bgSurface,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpace.xl,
        vertical: AppSpace.xl,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.lg,
        side: BorderSide(color: AppColors.borderSubtle),
      ),
      child: Padding(
        padding: AppSpace.allXl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: hunterTint.withValues(alpha: 0.12),
                    borderRadius: AppRadius.md,
                  ),
                  child: Icon(
                    Icons.radar_rounded,
                    size: AppIcon.md,
                    color: hunterTint,
                  ),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Text(
                    'Hunter role unlocked',
                    style: AppText.subtitle(
                      AppColors.textPrimary,
                      weight: AppText.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.md),
            Text(
              'Hunter space has your Hub: your gems, updates and tips.',
              style: AppText.body(AppColors.textMuted),
            ),
            const SizedBox(height: AppSpace.xl),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: FilledButton(
                // The same switch the space switcher makes. Popping first so
                // the switch overlay is not drawn under this dialog.
                onPressed: () {
                  final auth = context.read<AuthStore>();
                  Navigator.of(context).pop();
                  auth.switchSpaceWithTransition('hunter');
                },
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: onAccent,
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.md,
                  ),
                  textStyle: AppText.body(onAccent, weight: AppText.bold),
                ),
                child: const Text('Go to Hunter space'),
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: BorderSide(color: AppColors.borderMuted),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.md,
                  ),
                  textStyle: AppText.body(
                    AppColors.textPrimary,
                    weight: AppText.semibold,
                  ),
                ),
                child: const Text('Not now'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
