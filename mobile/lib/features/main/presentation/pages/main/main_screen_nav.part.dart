part of '../main_screen.dart';

class _FloatingComposerFab extends StatelessWidget {
  const _FloatingComposerFab({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onPressed();
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary400, AppColors.primary600],
          ),
          borderRadius: BorderRadius.circular(AppRadius.lgValue),
          border: Border.all(
            color: AppColors.bgBase,
            width: 3,
          ),
        ),
        child: const Icon(
          Icons.add_rounded,
          color: Colors.black,
          size: AppIcon.lg,
        ),
      ),
    );
  }
}
