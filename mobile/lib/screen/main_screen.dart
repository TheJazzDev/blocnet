import 'package:blocnet/app/theme.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/hunter/presentation/pages/hunter_hub_screen.dart';
import 'package:blocnet/features/projects/presentation/sections/home.dart';
import 'package:blocnet/features/projects/presentation/sections/projects/discover.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/screen/community_screen.dart';
import 'package:blocnet/screen/profile_screen.dart';
import 'package:blocnet/screen/wallet_screen.dart';
import 'package:blocnet/services/auth_store.dart';
import 'package:blocnet/services/notifications_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

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

  int _userIndex = 0;
  int _hunterIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _userIndex = widget.initialIndex.clamp(0, 4);
    _hunterIndex = widget.initialIndex.clamp(0, 4);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<NotificationsStore>().fetchNotificationsOnce();
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

    if (_lastIsHunterSpace == null) {
      _lastIsHunterSpace = isHunterSpace;
      return;
    }

    if (_lastIsHunterSpace == isHunterSpace) return;

    final token = ++_spaceSwitchToken;

    // When switching spaces, keep the user on Profile in the target space.
    setState(() {
      _isSwitchingSpace = true;
      if (isHunterSpace) {
        _hunterIndex = 4;
      } else {
        _userIndex = 4;
      }
    });

    _lastIsHunterSpace = isHunterSpace;

    Future<void>.delayed(const Duration(seconds: 2), () {
      if (!mounted || token != _spaceSwitchToken) return;
      setState(() => _isSwitchingSpace = false);
    });
  }

  void _onUserNavTap(int pageIndex) {
    if (_userIndex == pageIndex) return;
    HapticFeedback.selectionClick();
    setState(() => _userIndex = pageIndex);
  }

  void _onHunterNavTap(int pageIndex) {
    if (_hunterIndex == pageIndex) return;
    HapticFeedback.selectionClick();
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
        if (_isSwitchingSpace) const _SpaceSwitchOverlay(),
      ],
    );
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
