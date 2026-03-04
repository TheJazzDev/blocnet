import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/services/auth/auth_store.dart';
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

  Future<void> _submit() async {
    if (_isSubmitting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgSurface,
        title: Text(
          'Deactivate account?',
          style: AppTypography.custom(
            color: AppColors.textPrimary,
            size: 16,
            weight: FontWeight.w700,
          ),
        ),
        content: Text(
          'You will be logged out and your profile will be hidden until reactivated.',
          style: AppTypography.custom(
            color: AppColors.textSecondary,
            size: 13,
            weight: FontWeight.w400,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
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
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Deactivate',
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

    if (confirmed != true || !mounted) return;

    setState(() => _isSubmitting = true);

    final reason = _reasonController.text.trim();
    final authStore = context.read<AuthStore>();
    final success = await authStore.deactivateAccount(
      reason: reason.isEmpty ? null : reason,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (!success) {
      final error = authStore.lastError ?? 'Failed to deactivate account';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Account deactivated')),
    );
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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Before you continue',
                  style: AppTypography.custom(
                    color: AppColors.textPrimary,
                    size: 14,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your profile is hidden from other users.\nYou can no longer sign in until your account is reactivated.\nYour data is preserved.',
                  style: AppTypography.custom(
                    color: AppColors.textSecondary,
                    size: 13,
                    weight: FontWeight.w400,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Reason (optional)',
            style: AppTypography.custom(
              color: AppColors.textMuted,
              size: 12,
              weight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _reasonController,
            maxLines: 4,
            minLines: 3,
            maxLength: 500,
            style: AppTypography.custom(
              color: AppColors.textPrimary,
              size: 14,
              weight: FontWeight.w400,
            ),
            decoration: InputDecoration(
              hintText: 'Tell us why you are leaving (optional)',
              hintStyle: AppTypography.custom(
                color: AppColors.textFaint,
                size: 13,
                weight: FontWeight.w400,
              ),
              filled: true,
              fillColor: AppColors.bgSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.borderSubtle),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.borderSubtle),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary400),
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 46,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error500,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Deactivate Account',
                      style: AppTypography.custom(
                        color: Colors.white,
                        size: 13,
                        weight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
