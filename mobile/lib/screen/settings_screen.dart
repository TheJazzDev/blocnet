import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/notifications/data/models/notification_preferences_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/services/auth_store.dart';
import 'package:blocnet/services/notification_settings_store.dart';
import 'package:blocnet/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _lastShownError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthStore>();
      context
          .read<NotificationSettingsStore>()
          .fetchInitialOnce(userId: auth.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationSettingsStore>(
      builder: (context, settingsStore, _) {
        final prefs = settingsStore.preferences;
        final catalog = settingsStore.catalog;

        final error = settingsStore.lastError;
        if (error != null &&
            error.isNotEmpty &&
            error != _lastShownError &&
            mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            if (_lastShownError == error) return;
            _lastShownError = error;
            AppSnackbar.showError(context, error);
          });
        }

        return Scaffold(
          backgroundColor: AppColors.bgBase,
          appBar: const CustomAppBar(
            title: 'Settings',
            backButton: true,
            showSearch: false,
            showFilter: false,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SettingsHeader(),
                const SizedBox(height: 20),
                if (settingsStore.isLoading && !settingsStore.hasLoaded) ...[
                  const SizedBox(
                    height: 220,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ] else if (prefs == null || catalog == null) ...[
                  _SettingsRetryCard(
                    onRetry: settingsStore.refresh,
                  ),
                ] else ...[
                  _buildNotificationsSection(
                    context: context,
                    settingsStore: settingsStore,
                    prefs: prefs,
                  ),
                  const SizedBox(height: 20),
                  _buildCategoriesSection(
                    context: context,
                    settingsStore: settingsStore,
                    prefs: prefs,
                    catalog: catalog,
                  ),
                  const SizedBox(height: 20),
                  _buildPrivacySection(context),
                  const SizedBox(height: 20),
                ],
                _SignOutButton(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrivacySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Privacy & Security'),
        const SizedBox(height: 8),
        _SettingsNavigationTile(
          icon: Icons.block_outlined,
          title: 'Blocked users',
          subtitle: 'Manage your blocked accounts',
          onTap: () {
            Navigator.pushNamed(context, AppRoutes.blockedUsers);
          },
        ),
        _SettingsNavigationTile(
          icon: Icons.no_accounts_outlined,
          title: 'Deactivate account',
          subtitle: 'Temporarily disable your account',
          onTap: () {
            Navigator.pushNamed(context, AppRoutes.deactivateAccount);
          },
        ),
      ],
    );
  }

  Widget _buildNotificationsSection({
    required BuildContext context,
    required NotificationSettingsStore settingsStore,
    required NotificationPreferences prefs,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Notifications'),
        const SizedBox(height: 8),
        _SettingSwitchTile(
          icon: Icons.notifications_outlined,
          title: 'Push notifications',
          subtitle: 'Get in-app and device alerts',
          value: prefs.masterEnabled,
          onChanged: settingsStore.isSaving
              ? null
              : (value) {
                  settingsStore.setMasterEnabled(value);
                },
        ),
        _SettingSwitchTile(
          icon: Icons.mail_outline,
          title: 'Email digest',
          subtitle:
              'Daily summary at ${_formatLocalDigestTime(prefs.digestHourLocal, prefs.digestMinuteLocal)}',
          value: prefs.digestEmailEnabled,
          onChanged: settingsStore.isSaving
              ? null
              : (value) {
                  settingsStore.setDigestEmailEnabled(value);
                },
        ),
        _CadenceSelector(
          cadence: prefs.digestCadence,
          disabled: settingsStore.isSaving || !prefs.digestEmailEnabled,
          onChanged: (next) {
            settingsStore.setDigestCadence(next);
          },
        ),
      ],
    );
  }

  Widget _buildCategoriesSection({
    required BuildContext context,
    required NotificationSettingsStore settingsStore,
    required NotificationPreferences prefs,
    required NotificationPreferencesCatalog catalog,
  }) {
    if (catalog.categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Notification Categories'),
        const SizedBox(height: 8),
        ...catalog.categories.map(
          (category) => _SettingSwitchTile(
            icon: _iconForCategory(category.key),
            title: category.label,
            subtitle: _buildCategorySubtitle(category),
            value: prefs.isCategoryEnabled(category.key),
            onChanged: settingsStore.isSaving || !prefs.masterEnabled
                ? null
                : (value) {
                    settingsStore.setCategoryEnabled(category.key, value);
                  },
          ),
        ),
      ],
    );
  }

  String _buildCategorySubtitle(
      NotificationPreferenceCategoryCatalog category) {
    if (category.types.isEmpty) {
      return 'No linked events';
    }

    if (category.types.length == 1) {
      return _humanizeType(category.types.first);
    }

    return '${_humanizeType(category.types.first)} + ${category.types.length - 1} more';
  }

  String _humanizeType(String raw) {
    final words = raw.split('_');
    return words
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  IconData _iconForCategory(String key) {
    switch (key) {
      case 'updates':
        return Icons.campaign_outlined;
      case 'social':
        return Icons.people_alt_outlined;
      case 'governance':
        return Icons.hub_outlined;
      case 'wallet':
        return Icons.account_balance_wallet_outlined;
      case 'mining_referrals':
        return Icons.bolt_outlined;
      case 'rewards':
        return Icons.workspace_premium_outlined;
      case 'system':
        return Icons.settings_suggest_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  String _formatLocalDigestTime(int hour, int minute) {
    final date = DateTime(2026, 1, 1, hour, minute);
    final formatted = TimeOfDay.fromDateTime(date).format(context);
    return formatted;
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _SettingsHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontFamily: 'Geist',
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Control how you receive Blocnet updates.',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 13,
            fontFamily: 'Geist',
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        color: AppColors.textFaint,
        fontSize: 10,
        fontFamily: 'Geist',
        fontWeight: FontWeight.w600,
        letterSpacing: 1.0,
      ),
    );
  }
}

// ─── Switch Tile ──────────────────────────────────────────────────────────────

class _SettingSwitchTile extends StatelessWidget {
  const _SettingSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onChanged != null;
    final iconColor = value ? AppColors.teal400 : AppColors.textMuted;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.bgSurface,
            AppColors.bgSurface.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value
              ? AppColors.teal400.withValues(alpha: 0.25)
              : AppColors.borderSubtle,
          width: 1.5,
        ),
        boxShadow: value
            ? [
                BoxShadow(
                  color: AppColors.teal400.withValues(alpha: 0.08),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  iconColor.withValues(alpha: 0.15),
                  iconColor.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: iconColor.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.custom(
                    color: isEnabled
                        ? AppColors.textPrimary
                        : AppColors.textPrimary.withValues(alpha: 0.7),
                    size: 14,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.custom(
                    color: isEnabled
                        ? AppColors.textMuted
                        : AppColors.textMuted.withValues(alpha: 0.7),
                    size: 12,
                    weight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.teal400,
            activeTrackColor: AppColors.teal500.withValues(alpha: 0.35),
            inactiveThumbColor: AppColors.textFaint,
            inactiveTrackColor: AppColors.bgElevated,
          ),
        ],
      ),
    );
  }
}

class _CadenceSelector extends StatelessWidget {
  const _CadenceSelector({
    required this.cadence,
    required this.onChanged,
    this.disabled = false,
  });

  final String cadence;
  final ValueChanged<String> onChanged;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(
            Icons.schedule_outlined,
            size: 20,
            color: disabled
                ? AppColors.textMuted.withValues(alpha: 0.7)
                : AppColors.textMuted,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Digest cadence',
              style: AppTypography.custom(
                color: disabled
                    ? AppColors.textPrimary.withValues(alpha: 0.7)
                    : AppColors.textPrimary,
                size: 14,
                weight: FontWeight.w700,
              ),
            ),
          ),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment<String>(value: 'daily', label: Text('Daily')),
              ButtonSegment<String>(value: 'weekly', label: Text('Weekly')),
            ],
            selected: {cadence == 'weekly' ? 'weekly' : 'daily'},
            onSelectionChanged:
                disabled ? null : (selection) => onChanged(selection.first),
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              foregroundColor: WidgetStateProperty.all(AppColors.textPrimary),
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.teal500.withValues(alpha: 0.35);
                }
                return AppColors.bgElevated;
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsRetryCard extends StatelessWidget {
  const _SettingsRetryCard({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Unable to load notification settings.',
            style: AppTypography.custom(
              color: AppColors.textPrimary,
              size: 14,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap retry to fetch your latest preferences.',
            style: AppTypography.custom(
              color: AppColors.textMuted,
              size: 12,
              weight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: () {
              onRetry();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

// ─── Navigation Tile ──────────────────────────────────────────────────────────

class _SettingsNavigationTile extends StatelessWidget {
  const _SettingsNavigationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.bgSurface,
              AppColors.bgSurface.withValues(alpha: 0.85),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.borderSubtle,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.textMuted.withValues(alpha: 0.15),
                    AppColors.textMuted.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.textMuted.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Icon(icon, size: 20, color: AppColors.textMuted),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.custom(
                      color: AppColors.textPrimary,
                      size: 14,
                      weight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.custom(
                      color: AppColors.textMuted,
                      size: 12,
                      weight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: AppColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sign Out Button ──────────────────────────────────────────────────────────

class _SignOutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await context.read<AuthStore>().signOut();
        if (!context.mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.signIn,
          (Route<dynamic> route) => false,
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.error500.withValues(alpha: 0.08),
              AppColors.error500.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.error500.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.error500.withValues(alpha: 0.1),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.error500.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.error500.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.logout_rounded,
                size: 16,
                color: AppColors.error500,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Sign Out',
              style: AppTypography.custom(
                color: AppColors.error500,
                weight: FontWeight.w700,
                size: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
