import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/profile/presentation/widgets/edit_profile/profile_primary_button.dart';
import 'package:blocnet/features/profile/presentation/widgets/edit_profile/profile_text_field.dart';
import 'package:blocnet/features/profile/presentation/widgets/section_label.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:blocnet/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DeactivateAccountScreen extends StatefulWidget {
  const DeactivateAccountScreen({super.key});

  @override
  State<DeactivateAccountScreen> createState() =>
      _DeactivateAccountScreenState();
}

class _DeactivateAccountScreenState extends State<DeactivateAccountScreen> {
  final TextEditingController _reasonController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<bool> _confirm() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgSurface,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.lg,
          side: BorderSide(color: AppColors.borderSubtle),
        ),
        title: Text(
          'Deactivate account?',
          style: AppText.subtitle(AppColors.textPrimary, weight: AppText.bold),
        ),
        content: Text(
          'You are signed out now and hidden until reactivated.',
          style: AppText.body(AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style:
                  AppText.label(AppColors.textMuted, weight: AppText.semibold),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Deactivate',
              style: AppText.label(AppColors.error500, weight: AppText.bold),
            ),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!await _confirm() || !mounted) return;

    setState(() => _isSubmitting = true);
    final reason = _reasonController.text.trim();
    final authStore = context.read<AuthStore>();
    final success = await authStore.deactivateAccount(
      reason: reason.isEmpty ? null : reason,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (!success) {
      AppSnackbar.showError(
        context,
        authStore.lastError ?? 'Could not deactivate your account',
      );
      return;
    }

    AppSnackbar.showSuccess(context, 'Account deactivated');
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.signIn,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: const CustomAppBar(
        title: 'Deactivate Account',
        backButton: true,
        showSearch: false,
        showFilter: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpace.lg, AppSpace.lg, AppSpace.lg, AppSpace.xl),
        children: [
          const SectionLabel('What happens', icon: Icons.info_outline_rounded),
          AppSpace.gapSm,
          AppRowGroup(
            children: [
              AppListRow(
                icon: Icons.visibility_off_outlined,
                iconColor: AppColors.warning500,
                title: 'Profile hidden',
              ),
              AppListRow(
                icon: Icons.logout_rounded,
                iconColor: AppColors.warning500,
                title: 'Signed out until reactivated',
              ),
              AppListRow(
                icon: Icons.inventory_2_outlined,
                iconColor: AppColors.successColor,
                title: 'Your data is kept',
              ),
            ],
          ),
          AppSpace.gapXl,
          const SectionLabel('Reason (optional)'),
          AppSpace.gapSm,
          ProfileTextField(
            controller: _reasonController,
            hint: 'Why are you leaving?',
            minLines: 3,
            maxLines: 4,
            maxLength: 500,
          ),
          AppSpace.gapLg,
          ProfilePrimaryButton(
            label: 'Deactivate account',
            busy: _isSubmitting,
            onPressed: _submit,
            background: AppColors.error500,
            foreground: Colors.white,
          ),
        ],
      ),
    );
  }
}
