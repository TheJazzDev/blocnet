import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/features/profile/presentation/widgets/profile_body/hunter_profile_body.dart';
import 'package:blocnet/features/profile/presentation/widgets/profile_body/user_profile_body.dart';
import 'package:blocnet/services/auth_store.dart';
import 'package:flutter/material.dart';
import 'package:blocnet/app/typography.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    this.embeddedInMainShell = false,
  });

  final bool embeddedInMainShell;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();
    final profileBody = auth.isInHunterSpace
        ? HunterProfileBody(
            auth: auth,
            onSignOut: () => _confirmSignOut(context, auth),
          )
        : UserProfileBody(
            auth: auth,
            onSignOut: () => _confirmSignOut(context, auth),
          );

    final content = embeddedInMainShell
        ? ColoredBox(
            color: AppColors.bgBase,
            child: profileBody,
          )
        : Scaffold(
            backgroundColor: AppColors.bgBase,
            appBar: const CustomAppBar(
              title: 'Profile',
              backButton: true,
              showSearch: false,
              showFilter: false,
              showSpaceSwitcher: true,
            ),
            body: profileBody,
          );

    return Stack(
      children: [
        content,
        if (auth.isSwitchingSpace) const _ProfileSpaceSwitchOverlay(),
      ],
    );
  }

  Future<void> _confirmSignOut(BuildContext context, AuthStore auth) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: AppColors.borderSubtle.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        title: Text(
          'Sign Out',
          style: AppTypography.custom(
            color: AppColors.textPrimary,
            weight: FontWeight.w700,
            size: 16,
          ),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: AppTypography.custom(
            color: AppColors.textSecondary,
            size: 14,
            weight: FontWeight.w500,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: Text(
              'Cancel',
              style: AppTypography.custom(
                color: AppColors.textMuted,
                size: 13,
                weight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              backgroundColor: AppColors.error500.withValues(alpha: 0.12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Sign Out',
              style: AppTypography.custom(
                color: AppColors.error500,
                size: 13,
                weight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await auth.signOut();
    }
  }
}

class _ProfileSpaceSwitchOverlay extends StatelessWidget {
  const _ProfileSpaceSwitchOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AbsorbPointer(
        child: Container(
          color: Colors.black,
          child: Center(
            child: SizedBox(
              width: 160,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 4,
                  color: AppColors.primary400,
                  backgroundColor: Colors.white.withValues(alpha: 0.18),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
