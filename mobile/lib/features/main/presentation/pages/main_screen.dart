import 'package:blocnet/app/theme.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/hunter/presentation/pages/hunter_hub_screen.dart';
import 'package:blocnet/features/mining/presentation/pages/mining_screen.dart';
import 'package:blocnet/features/projects/presentation/sections/home.dart';
import 'package:blocnet/features/projects/presentation/sections/projects/discover.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/features/community/presentation/pages/community_screen.dart';
import 'package:blocnet/features/profile/presentation/pages/profile_screen.dart';
import 'package:blocnet/features/wallet/presentation/pages/wallet_screen.dart';
import 'package:blocnet/services/auth_store.dart';
import 'package:blocnet/services/connectivity_store.dart';
import 'package:blocnet/services/mining_store.dart';
import 'package:blocnet/services/notifications_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:blocnet/app/typography.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'main/main_screen_shells.part.dart';
part 'main/main_screen_nav.part.dart';
part 'main/main_screen_composer.part.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  bool? _lastIsHunterSpace;
  bool _isSwitchingSpace = false;
  int _spaceSwitchToken = 0;
  bool _hasCheckedReferralPrompt = false;
  bool _isShowingHunterOnboarding = false;
  String? _checkedHunterOnboardingUserId;

  int _userIndex = 0;
  int _hunterIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _userIndex = widget.initialIndex.clamp(0, 5);
    _hunterIndex = widget.initialIndex.clamp(0, 5);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<NotificationsStore>().fetchNotificationsOnce();
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
    context.read<NotificationsStore>().refreshNotifications();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isHunterSpace = context.watch<AuthStore>().isInHunterSpace;
    _maybePromptHunterOnboarding();

    if (_lastIsHunterSpace == null) {
      _lastIsHunterSpace = isHunterSpace;
      return;
    }

    if (_lastIsHunterSpace == isHunterSpace) return;
    final wasHunterSpace = _lastIsHunterSpace!;

    final token = ++_spaceSwitchToken;

    // Check if there's a pending navigation request
    _checkPendingNavigation().then((targetTab) {
      if (!mounted || token != _spaceSwitchToken) return;

      setState(() {
        _isSwitchingSpace = true;
        if (isHunterSpace) {
          _hunterIndex = targetTab ??
              (wasHunterSpace
                  ? _hunterIndex
                  : _mapUserToHunterIndex(_userIndex));
        } else {
          _userIndex = targetTab ??
              (wasHunterSpace
                  ? _mapHunterToUserIndex(_hunterIndex)
                  : _userIndex);
        }
      });

      _lastIsHunterSpace = isHunterSpace;

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

  int _mapUserToHunterIndex(int userIndex) {
    if (userIndex == 2) {
      // Community in User space maps to Hunter Hub in Hunter space.
      return 2;
    }
    return userIndex.clamp(0, 5);
  }

  int _mapHunterToUserIndex(int hunterIndex) {
    if (hunterIndex == 2) {
      // Hunter Hub in Hunter space maps to Community in User space.
      return 2;
    }
    return hunterIndex.clamp(0, 5);
  }

  void _onUserNavTap(int pageIndex) {
    if (_userIndex == pageIndex) return;
    setState(() => _userIndex = pageIndex);
  }

  void _onHunterNavTap(int pageIndex) {
    if (_hunterIndex == pageIndex) return;
    setState(() => _hunterIndex = pageIndex);
  }

  void _onFabTap(BuildContext context) {
    HapticFeedback.mediumImpact();
    _openComposerSheet(context);
  }

  @override
  Widget build(BuildContext context) {
    final isHunterSpace = context.watch<AuthStore>().isInHunterSpace;

    return Stack(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 420),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            final isHunterChild =
                (child.key as ValueKey?)?.value?.toString() == 'hunter';
            final slide = Tween<Offset>(
              begin: Offset(isHunterChild ? 0.08 : -0.08, 0),
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
          child: isHunterSpace
              ? _HunterSpaceShell(
                  key: const ValueKey('hunter'),
                  currentIndex: _hunterIndex,
                  onNavTap: _onHunterNavTap,
                  onFabTap: () => _onFabTap(context),
                )
              : _UserSpaceShell(
                  key: const ValueKey('user'),
                  currentIndex: _userIndex,
                  onNavTap: _onUserNavTap,
                ),
        ),
        const _OfflineStatusBanner(),
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

    if (!mounted) {
      _isShowingHunterOnboarding = false;
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
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
              const SizedBox(height: 14),
              Text(
                'Hunter space unlocked',
                style: AppTypography.custom(
                  color: AppColors.textPrimary,
                  size: 18,
                  weight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You now have access to Hunter Hub, management tools, and hunter-specific rankings.',
                style: AppTypography.custom(
                  color: AppColors.textMuted,
                  size: 12,
                  weight: FontWeight.w500,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.borderSubtle),
                        foregroundColor: AppColors.textSecondary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Dismiss'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary500,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Got it'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    _isShowingHunterOnboarding = false;
    await prefs.setBool(key, true);
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

class _OfflineStatusBanner extends StatelessWidget {
  const _OfflineStatusBanner();

  @override
  Widget build(BuildContext context) {
    final isOffline = context.watch<ConnectivityStore>().isOffline;
    if (!isOffline) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: MediaQuery.paddingOf(context).top + 10,
      left: 16,
      right: 16,
      child: IgnorePointer(
        ignoring: true,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.warning500,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.24),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              'You are offline. Showing cached data.',
              style: AppTypography.custom(
                color: Colors.black,
                size: 12,
                weight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
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
