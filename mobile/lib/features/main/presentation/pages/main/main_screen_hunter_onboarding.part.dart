part of '../main_screen.dart';

/// Shown once when the hunter role is granted. The primary action takes the
/// member straight into the space the role unlocked.
class _HunterOnboardingDialog extends StatelessWidget {
  const _HunterOnboardingDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 22, vertical: AppSpace.xl),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.bgSurface,
              AppColors.bgSurface.withValues(alpha: 0.96),
            ],
          ),
          border: Border.all(
            color: AppColors.primary500.withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 20,
              spreadRadius: 1,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(
            AppSpace.lg, AppSpace.lg, AppSpace.lg, AppSpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary400,
                        AppColors.teal400,
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    size: AppIcon.lg,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Text(
                    'Hunter role unlocked',
                    style: AppTypography.custom(
                      color: AppColors.textPrimary,
                      size: AppText.subtitleSize,
                      weight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.md),
            Text(
              'You now have access to Hunter Hub, management tools, and hunter rankings.',
              style: AppTypography.custom(
                color: AppColors.textMuted,
                size: AppText.labelSize,
                weight: FontWeight.w500,
                height: 1.45,
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                // The same switch the space switcher makes. Popping first so
                // the switch overlay is not drawn under this dialog.
                onPressed: () {
                  final auth = context.read<AuthStore>();
                  Navigator.of(context).pop();
                  auth.switchSpaceWithTransition('hunter');
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary500,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.mdValue),
                  ),
                ),
                child: const Text('Go to Hunter space'),
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textMuted,
                  padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
                ),
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
