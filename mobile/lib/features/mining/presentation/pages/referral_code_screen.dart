import 'dart:async';

import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/mining/data/models/mining_models.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/engagement/mining_store.dart';
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
      final store = context.read<MiningStore>();
      unawaited(store.loadSnapshot(force: true));
      unawaited(store.loadReferralSummary(force: true));
    });
  }

  String? _normalizedCode(String? value) {
    final normalized = value?.trim().toUpperCase();
    if (normalized == null || normalized.isEmpty) return null;
    return _referralCodePattern.hasMatch(normalized) ? normalized : null;
  }

  // Matches the display-name resolution used elsewhere in the app (see
  // user_profile_body.dart / hunter_profile_body.dart): the real display
  // name takes priority, with the username shown separately as "@handle"
  // alongside it. Previously this prioritized username first, which made
  // the header row show "@jazzdev" twice — once as the "display name" and
  // once as the explicit username badge next to it.
  String _resolveDisplayName(AuthStore auth) {
    final displayName = auth.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    final email = auth.email?.trim();
    if (email != null && email.isNotEmpty) {
      return email.split('@').first;
    }

    final username = auth.username?.trim();
    if (username != null && username.isNotEmpty) {
      return '@$username';
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
                      borderRadius: BorderRadius.circular(AppRadius.mdValue),
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
                  left: AppSpace.lg,
                  right: AppSpace.lg,
                  top: AppSpace.lg,
                  bottom: AppSpace.lg + MediaQuery.of(context).viewInsets.bottom,
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
                          borderRadius: BorderRadius.circular(AppRadius.fullValue),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpace.md),
                    Text(
                      'Bind Referral Code',
                      style: AppTypography.custom(
                        size: AppText.titleSize,
                        weight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpace.sm),
                    TextField(
                      controller: controller,
                      maxLength: 8,
                      textCapitalization: TextCapitalization.characters,
                      style: AppTypography.custom(
                        size: AppText.bodySize,
                        weight: FontWeight.w400,
                        color: AppColors.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Enter 8-character code',
                        counterText: '',
                      ),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: AppSpace.sm),
                      Text(
                        error!,
                        style: AppTypography.custom(
                          size: AppText.bodySize,
                          weight: FontWeight.w400,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpace.md),
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
                                  size: AppText.labelSize,
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
    final referral = miningStore.referralSummary;
    final referralCode =
        _normalizedCode(auth.referralCode) ?? _normalizedCode(referral?.code);
    final displayName = _resolveDisplayName(auth);
    final username = auth.username?.trim();
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
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderSection(
              displayName: displayName,
              username: username,
            ),
            const SizedBox(height: AppSpace.xl),
            _ReferralCodeCard(
              code: referralCode ?? '--------',
              link: referralLink,
              enabled: referralCode != null,
            ),
            const SizedBox(height: AppSpace.xl),
            _StatsSection(
              totalReferrals: referral?.totalDirectReferrals ?? 0,
              activeReferrals: referral?.activeDirectReferrals ?? 0,
              loading: miningStore.isLoadingReferral && referral == null,
              errorMessage: referral == null ? miningStore.referralError : null,
              onRetry: () =>
                  unawaited(miningStore.loadReferralSummary(force: true)),
            ),
            const SizedBox(height: AppSpace.xl),
            _ReferrerSection(referral: referral),
            if (referral != null &&
                !referral.isBound &&
                referral.bindWindowOpen) ...[
              const SizedBox(height: AppSpace.xl),
              _BindReferrerCard(
                isBinding: miningStore.isBindingReferral,
                onBind: () => _showBindSheet(miningStore),
              ),
            ],
            if ((miningStore.lastError ?? '').isNotEmpty) ...[
              const SizedBox(height: AppSpace.lg),
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
  });

  final String displayName;
  final String? username;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Invite Friends',
          style: AppTypography.custom(
            color: AppColors.textPrimary,
            size: AppText.headlineSize,
            weight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        Text(
          'Share your referral code so new members can join through your profile.',
          style: AppTypography.custom(
            color: AppColors.textMuted,
            size: AppText.bodySize,
            weight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: AppSpace.md),
        Row(
          children: [
            Expanded(
              child: Text(
                displayName,
                style: AppTypography.custom(
                  color: AppColors.textPrimary,
                  size: AppText.bodySize,
                  weight: FontWeight.w700,
                ),
              ),
            ),
            if (username != null && username!.isNotEmpty)
              Text(
                '@$username',
                style: AppTypography.custom(
                  color: AppColors.textMuted,
                  size: AppText.labelSize,
                  weight: FontWeight.w600,
                ),
              ),
          ],
        ),
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
      padding: const EdgeInsets.all(AppSpace.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary500.withValues(alpha: 0.15),
            AppColors.teal500.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lgValue),
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
              size: AppText.labelSize,
              weight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: AppSpace.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl, vertical: AppSpace.md),
            decoration: BoxDecoration(
              color: AppColors.bgElevated,
              borderRadius: BorderRadius.circular(AppRadius.mdValue),
              border: Border.all(
                color: AppColors.borderSubtle,
                width: 1,
              ),
            ),
            child: Text(
              code,
              style: AppTypography.custom(
                color: AppColors.primary400,
                size: AppText.displaySize,
                weight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: AppSpace.lg),
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
              const SizedBox(width: AppSpace.md),
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
      icon: Icon(icon, size: AppIcon.md),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary500,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.mdValue),
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
    required this.errorMessage,
    required this.onRetry,
  });

  final int totalReferrals;
  final int activeReferrals;
  final bool loading;
  final String? errorMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final hasError = errorMessage != null && errorMessage!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.lgValue),
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
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
          if (hasError) ...[
            const SizedBox(height: AppSpace.md),
            GestureDetector(
              onTap: onRetry,
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.refresh_rounded,
                    size: AppIcon.sm,
                    color: AppColors.warning500,
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Flexible(
                    child: Text(
                      "Couldn't load referral totals. Tap to retry.",
                      style: AppTypography.custom(
                        color: AppColors.warning500,
                        size: AppText.labelSize,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
          size: AppIcon.lg,
        ),
        const SizedBox(height: AppSpace.sm),
        Text(
          value,
          style: AppTypography.custom(
            color: AppColors.textPrimary,
            size: AppText.titleSize,
            weight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpace.xs),
        Text(
          label,
          style: AppTypography.custom(
            color: AppColors.textFaint,
            size: AppText.captionSize,
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
      final normalizedUsername = referredBy.username?.trim().replaceAll('@', '');
      final referrerName =
          (normalizedUsername != null && normalizedUsername.isNotEmpty)
              ? '@$normalizedUsername'
              : 'linked referrer';
      final referrerCode = referredBy.code?.trim().toUpperCase();
      return _ReferrerCard(
        title: 'Your Referrer',
        subtitle: referrerName,
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
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.mdValue),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bind Referrer',
            style: AppTypography.custom(
              color: AppColors.textPrimary,
              size: AppText.bodySize,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            'Enter the invite code shared by your referrer.',
            style: AppTypography.custom(
              color: AppColors.textMuted,
              size: AppText.labelSize,
              weight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpace.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isBinding ? null : onBind,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: AppColors.primary500.withValues(alpha: 0.4),
                ),
                foregroundColor: AppColors.textPrimary,
                padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
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
                      size: AppIcon.sm,
                      color: AppColors.primary400,
                    ),
              label: Text(
                'Bind Referral Code',
                style: AppTypography.custom(
                  color: AppColors.textPrimary,
                  size: AppText.labelSize,
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
    this.code,
  });

  final String title;
  final String subtitle;
  final String? detail;
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
            size: AppText.subtitleSize,
            weight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpace.md),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpace.lg),
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(AppRadius.mdValue),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subtitle,
                style: AppTypography.custom(
                  color: AppColors.textPrimary,
                  size: AppText.bodySize,
                  weight: FontWeight.w700,
                ),
              ),
              if (code != null && code!.isNotEmpty) ...[
                const SizedBox(height: AppSpace.sm),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: AppSpace.xs),
                  decoration: BoxDecoration(
                    color: AppColors.bgElevated,
                    borderRadius: BorderRadius.circular(AppRadius.fullValue),
                  ),
                  child: Text(
                    'Code: $code',
                    style: AppTypography.custom(
                      color: AppColors.textSecondary,
                      size: AppText.captionSize,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              if (detail != null && detail!.isNotEmpty) ...[
                const SizedBox(height: AppSpace.sm),
                Text(
                  detail!,
                  style: AppTypography.custom(
                    color: AppColors.textFaint,
                    size: AppText.labelSize,
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
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: AppColors.warning500.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.mdValue),
        border: Border.all(color: AppColors.warning500.withValues(alpha: 0.4)),
      ),
      child: Text(
        message,
        style: AppTypography.custom(
          color: AppColors.warning500,
          size: AppText.labelSize,
          weight: FontWeight.w600,
        ),
      ),
    );
  }
}
