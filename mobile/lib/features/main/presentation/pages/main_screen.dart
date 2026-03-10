import 'package:blocnet/app/theme.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/hunter/presentation/pages/hunter_hub_screen.dart';
import 'package:blocnet/features/mining/presentation/pages/mining_screen.dart';
import 'package:blocnet/features/moderation/presentation/pages/moderation_hub_screen.dart';
import 'package:blocnet/features/projects/presentation/sections/home.dart';
import 'package:blocnet/features/projects/presentation/sections/projects/discover.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/features/community/presentation/pages/community_screen.dart';
import 'package:blocnet/features/profile/presentation/pages/profile_screen.dart';
import 'package:blocnet/features/wallet/presentation/pages/wallet_screen.dart';
import 'package:blocnet/services/auth/auth_store.dart';
// import 'package:blocnet/services/core/connectivity_store.dart';
import 'package:blocnet/services/engagement/mining_store.dart';
import 'package:blocnet/services/notifications/notifications_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:blocnet/app/typography.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'main/main_screen_shells.part.dart';
part 'main/main_screen_nav.part.dart';
part 'main/main_screen_composer.part.dart';
// part 'main/main_screen_offline_banner.part.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  static final Set<String> _hunterOnboardingInFlightUserIds = <String>{};

  String? _lastActiveSpace;
  bool _isSwitchingSpace = false;
  int _spaceSwitchToken = 0;
  bool _hasCheckedReferralPrompt = false;
  bool _isShowingHunterOnboarding = false;
  String? _checkedHunterOnboardingUserId;
  bool _didRequestInitialNotifications = false;

  int _userIndex = 0;
  int _hunterIndex = 0;
  int _moderationIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _userIndex = widget.initialIndex.clamp(0, 5);
    _hunterIndex = widget.initialIndex.clamp(0, 5);
    _moderationIndex = widget.initialIndex.clamp(0, 5);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _maybePromptReferralBind();
      _maybePromptHunterOnboarding();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;
    context.read<NotificationsStore>().refreshNotifications(category: 'all');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authStore = context.watch<AuthStore>();
    final activeSpace = authStore.activeSpace;

    if (!_didRequestInitialNotifications &&
        authStore.isAuthenticated &&
        !authStore.isBootstrapping) {
      _didRequestInitialNotifications = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<NotificationsStore>().fetchNotificationsOnce(
              category: 'all',
            );
      });
    }
    _maybePromptHunterOnboarding();

    if (_lastActiveSpace == null) {
      _lastActiveSpace = activeSpace;
      return;
    }

    if (_lastActiveSpace == activeSpace) return;
    final previousSpace = _lastActiveSpace!;

    final token = ++_spaceSwitchToken;

    // Check if there's a pending navigation request
    _checkPendingNavigation().then((targetTab) {
      if (!mounted || token != _spaceSwitchToken) return;

      setState(() {
        _isSwitchingSpace = true;
        if (activeSpace == 'hunter') {
          _hunterIndex = targetTab ?? _mapToHunterIndex(previousSpace, _userIndex, _moderationIndex);
        } else if (activeSpace == 'moderation') {
          _moderationIndex = targetTab ?? _mapToModerationIndex(previousSpace, _userIndex, _hunterIndex);
        } else {
          _userIndex = targetTab ?? _mapToUserIndex(previousSpace, _hunterIndex, _moderationIndex);
        }
      });

      _lastActiveSpace = activeSpace;

      Future<void>.delayed(const Duration(milliseconds: 300), () {
        if (!mounted || token != _spaceSwitchToken) return;
        setState(() => _isSwitchingSpace = false);
      });
    });
  }

  Future<int?> _checkPendingNavigation() async {
    final prefs = await SharedPreferences.getInstance();
    final targetTab = prefs.getInt('navigate_to_tab_after_switch');
    if (targetTab != null) {
      await prefs.remove('navigate_to_tab_after_switch');
      return targetTab;
    }
    return null;
  }

  int _mapToHunterIndex(String previousSpace, int userIndex, int moderationIndex) {
    if (previousSpace == 'user') {
      // Community in User space maps to Hunter Hub in Hunter space
      return userIndex == 2 ? 2 : userIndex.clamp(0, 5);
    } else if (previousSpace == 'moderation') {
      // Moderation in Moderation space maps to Hunter Hub in Hunter space
      return moderationIndex == 2 ? 2 : moderationIndex.clamp(0, 5);
    }
    return 2; // Default to Hunter Hub
  }

  int _mapToModerationIndex(String previousSpace, int userIndex, int hunterIndex) {
    if (previousSpace == 'user') {
      // Community in User space maps to Moderation Hub in Moderation space
      return userIndex == 2 ? 2 : userIndex.clamp(0, 5);
    } else if (previousSpace == 'hunter') {
      // Hunter Hub in Hunter space maps to Moderation Hub in Moderation space
      return hunterIndex == 2 ? 2 : hunterIndex.clamp(0, 5);
    }
    return 2; // Default to Moderation Hub
  }

  int _mapToUserIndex(String previousSpace, int hunterIndex, int moderationIndex) {
    if (previousSpace == 'hunter') {
      // Hunter Hub in Hunter space maps to Community in User space
      return hunterIndex == 2 ? 2 : hunterIndex.clamp(0, 5);
    } else if (previousSpace == 'moderation') {
      // Moderation Hub in Moderation space maps to Community in User space
      return moderationIndex == 2 ? 2 : moderationIndex.clamp(0, 5);
    }
    return 2; // Default to Community
  }

  void _onUserNavTap(int pageIndex) {
    if (_userIndex == pageIndex) return;
    setState(() => _userIndex = pageIndex);
  }

  void _onHunterNavTap(int pageIndex) {
    if (_hunterIndex == pageIndex) return;
    setState(() => _hunterIndex = pageIndex);
  }

  void _onModerationNavTap(int pageIndex) {
    if (_moderationIndex == pageIndex) return;
    setState(() => _moderationIndex = pageIndex);
  }

  void _onFabTap(BuildContext context) {
    HapticFeedback.mediumImpact();
    _openComposerSheet(context);
  }

  @override
  Widget build(BuildContext context) {
    final authStore = context.watch<AuthStore>();
    final activeSpace = authStore.activeSpace;

    Widget shell;
    if (activeSpace == 'hunter') {
      shell = _HunterSpaceShell(
        key: const ValueKey('hunter'),
        currentIndex: _hunterIndex,
        onNavTap: _onHunterNavTap,
        onFabTap: () => _onFabTap(context),
      );
    } else if (activeSpace == 'moderation') {
      shell = _ModerationSpaceShell(
        key: const ValueKey('moderation'),
        currentIndex: _moderationIndex,
        onNavTap: _onModerationNavTap,
      );
    } else {
      shell = _UserSpaceShell(
        key: const ValueKey('user'),
        currentIndex: _userIndex,
        onNavTap: _onUserNavTap,
      );
    }

    return Stack(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 420),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            final spaceKey = (child.key as ValueKey?)?.value?.toString();
            final slideX = spaceKey == 'hunter' ? 0.08 :
                          spaceKey == 'moderation' ? -0.08 :
                          spaceKey == 'user' ? -0.08 : 0.0;
            final slide = Tween<Offset>(
              begin: Offset(slideX, 0),
              end: Offset.zero,
            ).animate(animation);
            final scale =
                Tween<double>(begin: 0.985, end: 1).animate(animation);
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: slide,
                child: ScaleTransition(
                  scale: scale,
                  child: child,
                ),
              ),
            );
          },
          child: shell,
        ),
        // const _OfflineStatusBanner(),
        if (_isSwitchingSpace) const _SpaceSwitchOverlay(),
      ],
    );
  }

  Future<void> _maybePromptReferralBind() async {
    if (_hasCheckedReferralPrompt || !mounted) return;
    _hasCheckedReferralPrompt = true;

    final auth = context.read<AuthStore>();
    final miningStore = context.read<MiningStore>();
    final userId = auth.userId;
    if (!auth.isAuthenticated || userId == null || userId.isEmpty) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final promptSeenKey = 'blocnet_referral_prompt_seen_$userId';
    if (prefs.getBool(promptSeenKey) == true) {
      return;
    }

    await miningStore.loadSnapshot(force: true);
    if (!mounted) return;

    final snapshot = miningStore.snapshot;
    final referral = snapshot?.referral;
    if (snapshot == null ||
        referral == null ||
        referral.isBound ||
        !referral.bindWindowOpen) {
      await prefs.setBool(promptSeenKey, true);
      return;
    }

    final pendingCode = auth.pendingReferralCode?.trim().toUpperCase();
    if (pendingCode != null && pendingCode.isNotEmpty) {
      try {
        await miningStore.bindReferralCode(pendingCode);
        await auth.setPendingReferralCode(null);
      } catch (_) {
        // Keep pending code for manual bind attempt in Mining screen.
      }
      await prefs.setBool(promptSeenKey, true);
      return;
    }

    if (!mounted) return;

    final enteredCode = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _ReferralPromptSheet(),
    );

    if (!mounted) return;

    if (enteredCode != null && enteredCode.isNotEmpty) {
      try {
        await miningStore.bindReferralCode(enteredCode);
        await auth.setPendingReferralCode(null);
      } catch (_) {
        // Error is shown by MiningStore snackbar handler.
      }
    }

    await prefs.setBool(promptSeenKey, true);
  }

  Future<void> _maybePromptHunterOnboarding() async {
    if (!mounted || _isShowingHunterOnboarding) return;

    final auth = context.read<AuthStore>();
    final userId = auth.userId?.trim();
    if (!auth.isAuthenticated ||
        !auth.hasHunterSpace ||
        userId == null ||
        userId.isEmpty) {
      return;
    }
    if (_hunterOnboardingInFlightUserIds.contains(userId)) {
      return;
    }

    _hunterOnboardingInFlightUserIds.add(userId);
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = auth.hunterOnboardedKeyFor(userId);
      final alreadySeen = prefs.getBool(key) == true;
      if (alreadySeen) {
        _checkedHunterOnboardingUserId = userId;
        return;
      }
      if (_checkedHunterOnboardingUserId == userId) {
        return;
      }

      _isShowingHunterOnboarding = true;
      _checkedHunterOnboardingUserId = userId;

      // Reserve this onboarding key before showing UI so concurrent checks
      // (or duplicate mounted screen instances) cannot stack duplicate prompts.
      await prefs.setBool(key, true);

      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const _HunterOnboardingDialog(),
      );
    } finally {
      _isShowingHunterOnboarding = false;
      _hunterOnboardingInFlightUserIds.remove(userId);
    }
  }
}

class _SpaceSwitchOverlay extends StatelessWidget {
  const _SpaceSwitchOverlay();

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

class _TabMeta {
  const _TabMeta({
    required this.title,
    required this.showSearch,
    required this.showFilter,
    required this.showNotificationBell,
  });

  final String title;
  final bool showSearch;
  final bool showFilter;
  final bool showNotificationBell;
}

class _HunterOnboardingDialog extends StatelessWidget {
  const _HunterOnboardingDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
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
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
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
                    size: 22,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Hunter role unlocked',
                    style: AppTypography.custom(
                      color: AppColors.textPrimary,
                      size: 17,
                      weight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'You now have access to Hunter Hub, management tools, and hunter rankings.',
              style: AppTypography.custom(
                color: AppColors.textMuted,
                size: 12,
                weight: FontWeight.w500,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary500,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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

class _ReferralPromptSheet extends StatefulWidget {
  const _ReferralPromptSheet();

  @override
  State<_ReferralPromptSheet> createState() => _ReferralPromptSheetState();
}

class _ReferralPromptSheetState extends State<_ReferralPromptSheet> {
  final TextEditingController _controller = TextEditingController();
  final RegExp _codeRegex = RegExp(r'^[A-Z0-9]{8}$');
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 14,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderMuted,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Got a referral code?',
              style: AppTypography.custom(
                size: 18,
                weight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Bind once to activate referral boost tracking.',
              style: AppTypography.custom(
                size: 12,
                weight: FontWeight.w400,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
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
            if (_error != null) ...[
              const SizedBox(height: 4),
              Text(
                _error!,
                style: AppTypography.custom(
                  size: 12,
                  weight: FontWeight.w400,
                  color: Colors.redAccent,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(''),
                    child: Text(
                      'Skip',
                      style: AppTypography.custom(
                        size: 12,
                        weight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final code = _controller.text.trim().toUpperCase();
                      if (code.isEmpty) {
                        Navigator.of(context).pop('');
                        return;
                      }
                      if (!_codeRegex.hasMatch(code)) {
                        setState(() {
                          _error = 'Code must be 8 letters/numbers.';
                        });
                        return;
                      }
                      Navigator.of(context).pop(code);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary500,
                      foregroundColor: Colors.black,
                    ),
                    child: Text(
                      'Bind',
                      style: AppTypography.custom(
                        size: 12,
                        weight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
