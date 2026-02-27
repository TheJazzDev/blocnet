import 'dart:async';

import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/mining/data/models/mining_models.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/services/auth_store.dart';
import 'package:blocnet/services/mining_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class ReferralCodeScreen extends StatefulWidget {
  const ReferralCodeScreen({super.key});

  @override
  State<ReferralCodeScreen> createState() => _ReferralCodeScreenState();
}

class _ReferralCodeScreenState extends State<ReferralCodeScreen> {
  static final RegExp _referralCodePattern = RegExp(r'^[A-Z0-9]{8}$');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(context.read<MiningStore>().loadSnapshot(force: true));
    });
  }

  String? _normalizedCode(String? value) {
    final normalized = value?.trim().toUpperCase();
    if (normalized == null || normalized.isEmpty) return null;
    return _referralCodePattern.hasMatch(normalized) ? normalized : null;
  }

  String _resolveDisplayName(AuthStore auth) {
    final displayName = auth.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    final username = auth.username?.trim();
    if (username != null && username.isNotEmpty) {
      return '@$username';
    }

    final email = auth.email?.trim();
    if (email != null && email.isNotEmpty) {
      return email.split('@').first;
    }

    return 'Blocnet User';
  }

  Future<void> _showBindSheet(MiningStore store) async {
    final controller = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    String? error;
    bool validating = false;
    bool binding = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            Future<void> submit() async {
              final code = controller.text.trim().toUpperCase();
              if (code.length != 8) {
                setLocalState(
                  () => error = 'Referral code must be 8 characters.',
                );
                return;
              }

              setLocalState(() {
                error = null;
                validating = true;
              });

              final validation = await store.validateReferralCode(code);
              if (!mounted) return;

              if (validation == null || !validation.valid) {
                setLocalState(() {
                  validating = false;
                  error = 'Referral code is invalid.';
                });
                return;
              }

              setLocalState(() {
                validating = false;
                binding = true;
              });

              try {
                await store.bindReferralCode(code);
                if (!sheetContext.mounted) return;
                Navigator.of(sheetContext).pop();
                messenger.showSnackBar(
                  SnackBar(
                    content: const Text('Referral code bound successfully.'),
                    backgroundColor: AppColors.successColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              } catch (_) {
                if (!mounted) return;
                setLocalState(() {
                  binding = false;
                  error = store.lastError ?? 'Failed to bind referral code.';
                });
              }
            }

            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.borderMuted,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Bind Referral Code',
                      style: AppTypography.custom(
                        size: 18,
                        weight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: controller,
                      maxLength: 8,
                      textCapitalization: TextCapitalization.characters,
                      style: AppTypography.custom(
                        size: 14,
                        weight: FontWeight.w400,
                        color: AppColors.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Enter 8-character code',
                        counterText: '',
                      ),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        error!,
                        style: AppTypography.custom(
                          size: 12,
                          weight: FontWeight.w400,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: validating || binding ? null : submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary500,
                          foregroundColor: Colors.black,
                        ),
                        child: validating || binding
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.black,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Bind Code',
                                style: AppTypography.custom(
                                  size: 13,
                                  weight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();
    final miningStore = context.watch<MiningStore>();
    final referral = miningStore.snapshot?.referral;
    final referralCode =
        _normalizedCode(auth.referralCode) ?? _normalizedCode(referral?.code);
    final displayName = _resolveDisplayName(auth);
    final username = auth.username?.trim();
    final email = auth.email?.trim();
    final referralLink = referralCode != null
        ? 'https://blocnet.app/ref/$referralCode'
        : 'https://blocnet.app';

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: const CustomAppBar(
        title: 'Referral Code',
        backButton: true,
        showSearch: false,
        showFilter: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderSection(
              displayName: displayName,
              username: username,
              email: email,
            ),
            const SizedBox(height: 24),
            _ReferralCodeCard(
              code: referralCode ?? '--------',
              link: referralLink,
              enabled: referralCode != null,
            ),
            const SizedBox(height: 24),
            _StatsSection(
              totalReferrals: referral?.totalDirectReferrals ?? 0,
              activeReferrals: referral?.activeDirectReferrals ?? 0,
              loading: miningStore.isLoadingSnapshot && referral == null,
            ),
            const SizedBox(height: 24),
            _ReferrerSection(referral: referral),
            if (referral != null &&
                !referral.isBound &&
                referral.bindWindowOpen) ...[
              const SizedBox(height: 20),
              _BindReferrerCard(
                isBinding: miningStore.isBindingReferral,
                onBind: () => _showBindSheet(miningStore),
              ),
            ],
            if ((miningStore.lastError ?? '').isNotEmpty) ...[
              const SizedBox(height: 16),
              _WarningBanner(message: miningStore.lastError!),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({
    required this.displayName,
    required this.username,
    required this.email,
  });

  final String displayName;
  final String? username;
  final String? email;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Invite Friends',
          style: AppTypography.custom(
            color: AppColors.textPrimary,
            size: 22,
            weight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Share your referral code so new members can join through your profile.',
          style: AppTypography.custom(
            color: AppColors.textMuted,
            size: 14,
            weight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                displayName,
                style: AppTypography.custom(
                  color: AppColors.textPrimary,
                  size: 14,
                  weight: FontWeight.w700,
                ),
              ),
            ),
            if (username != null && username!.isNotEmpty)
              Text(
                '@$username',
                style: AppTypography.custom(
                  color: AppColors.textMuted,
                  size: 12,
                  weight: FontWeight.w600,
                ),
              ),
          ],
        ),
        if (email != null && email!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            email!,
            style: AppTypography.custom(
              color: AppColors.textFaint,
              size: 12,
              weight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

class _ReferralCodeCard extends StatelessWidget {
  const _ReferralCodeCard({
    required this.code,
    required this.link,
    required this.enabled,
  });

  final String code;
  final String link;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary500.withValues(alpha: 0.15),
            AppColors.teal500.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary500.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Your Referral Code',
            style: AppTypography.custom(
              color: AppColors.textFaint,
              size: 12,
              weight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.bgElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.borderSubtle,
                width: 1,
              ),
            ),
            child: Text(
              code,
              style: AppTypography.custom(
                color: AppColors.primary400,
                size: 28,
                weight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'Copy Code',
                  icon: Icons.copy_rounded,
                  enabled: enabled,
                  onPressed: () {
                    if (!enabled) return;
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Referral code copied!',
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: AppColors.successColor,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  label: 'Copy Link',
                  icon: Icons.link_rounded,
                  enabled: enabled,
                  onPressed: () {
                    if (!enabled) return;
                    Clipboard.setData(ClipboardData(text: link));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Referral link copied!',
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: AppColors.successColor,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary500,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  const _StatsSection({
    required this.totalReferrals,
    required this.activeReferrals,
    required this.loading,
  });

  final int totalReferrals;
  final int activeReferrals;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            label: 'Total Referrals',
            value: loading ? '...' : '$totalReferrals',
            icon: Icons.people_outline,
          ),
          Container(
            height: 40,
            width: 1,
            color: AppColors.borderSubtle,
          ),
          _StatItem(
            label: 'Active Referrals',
            value: loading ? '...' : '$activeReferrals',
            icon: Icons.trending_up_rounded,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppColors.primary400,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTypography.custom(
            color: AppColors.textPrimary,
            size: 20,
            weight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.custom(
            color: AppColors.textFaint,
            size: 11,
            weight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ReferrerSection extends StatelessWidget {
  const _ReferrerSection({required this.referral});

  final ReferralSummaryModel? referral;

  @override
  Widget build(BuildContext context) {
    final referredBy = referral?.referredBy;

    if (referral == null) {
      return const SizedBox.shrink();
    }

    if (referredBy != null) {
      final referrerName = referredBy.displayName?.trim().isNotEmpty == true
          ? referredBy.displayName!.trim()
          : (referredBy.email?.trim().isNotEmpty == true
              ? referredBy.email!.trim()
              : 'Unknown');
      final referrerCode = referredBy.code?.trim().toUpperCase();
      return _ReferrerCard(
        title: 'Your Referrer',
        subtitle: referrerName,
        email: referredBy.email?.trim(),
        code: referrerCode,
      );
    }

    if (referral!.bindWindowOpen) {
      return const _ReferrerCard(
        title: 'Your Referrer',
        subtitle: 'No referrer is linked yet.',
        detail: 'Use the bind action below if your account was invited.',
      );
    }

    return const _ReferrerCard(
      title: 'Your Referrer',
      subtitle: 'No referrer linked.',
      detail: 'Referral bind window is closed for this account.',
    );
  }
}

class _BindReferrerCard extends StatelessWidget {
  const _BindReferrerCard({
    required this.isBinding,
    required this.onBind,
  });

  final bool isBinding;
  final VoidCallback onBind;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
            'Bind Referrer',
            style: AppTypography.custom(
              color: AppColors.textPrimary,
              size: 15,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Enter the invite code shared by your referrer.',
            style: AppTypography.custom(
              color: AppColors.textMuted,
              size: 12,
              weight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isBinding ? null : onBind,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: AppColors.primary500.withValues(alpha: 0.4),
                ),
                foregroundColor: AppColors.textPrimary,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: isBinding
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        color: AppColors.primary400,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(
                      Icons.link_rounded,
                      size: 16,
                      color: AppColors.primary400,
                    ),
              label: Text(
                'Bind Referral Code',
                style: AppTypography.custom(
                  color: AppColors.textPrimary,
                  size: 12,
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

class _ReferrerCard extends StatelessWidget {
  const _ReferrerCard({
    required this.title,
    required this.subtitle,
    this.detail,
    this.email,
    this.code,
  });

  final String title;
  final String subtitle;
  final String? detail;
  final String? email;
  final String? code;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.custom(
            color: AppColors.textPrimary,
            size: 16,
            weight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
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
                subtitle,
                style: AppTypography.custom(
                  color: AppColors.textPrimary,
                  size: 14,
                  weight: FontWeight.w700,
                ),
              ),
              if (email != null && email!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  email!,
                  style: AppTypography.custom(
                    color: AppColors.textMuted,
                    size: 12,
                    weight: FontWeight.w500,
                  ),
                ),
              ],
              if (code != null && code!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.bgElevated,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Code: $code',
                    style: AppTypography.custom(
                      color: AppColors.textSecondary,
                      size: 11,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              if (detail != null && detail!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  detail!,
                  style: AppTypography.custom(
                    color: AppColors.textFaint,
                    size: 12,
                    weight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning500.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning500.withValues(alpha: 0.4)),
      ),
      child: Text(
        message,
        style: AppTypography.custom(
          color: AppColors.warning500,
          size: 12,
          weight: FontWeight.w600,
        ),
      ),
    );
  }
}
