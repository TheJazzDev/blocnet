import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// "Continue with Google": the app's dark outlined button with the Google
/// mark, 44px tall.
class AuthGoogleButton extends StatelessWidget {
  const AuthGoogleButton({
    super.key,
    required this.label,
    required this.isEnabled,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final bool isEnabled;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = isEnabled && !isLoading;
    return Opacity(
      opacity: isEnabled || isLoading ? 1 : 0.45,
      child: Material(
        color: AppColors.bgElevated,
        borderRadius: AppRadius.md,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              borderRadius: AppRadius.md,
              border: Border.all(color: AppColors.borderMuted),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  SizedBox(
                    width: AppIcon.sm,
                    height: AppIcon.sm,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textPrimary,
                    ),
                  )
                else
                  SvgPicture.asset(
                    'assets/icons/google_g.svg',
                    width: AppIcon.md,
                    height: AppIcon.md,
                  ),
                AppSpace.wGapMd,
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(
                      AppColors.textPrimary,
                      weight: AppText.semibold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A hairline either side of a short muted label ("or use email").
class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({super.key, this.label = 'or'});

  final String label;

  @override
  Widget build(BuildContext context) {
    Widget line() => Expanded(
          child: Container(height: 1, color: AppColors.borderSubtle),
        );
    return Row(
      children: [
        line(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
          child: Text(label, style: AppText.label(AppColors.textFaint)),
        ),
        line(),
      ],
    );
  }
}
