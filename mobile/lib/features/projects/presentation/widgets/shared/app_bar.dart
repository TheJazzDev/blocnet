import 'package:blocnet/app/theme.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/auth/presentation/widgets/space_switcher.dart';
import 'package:blocnet/features/projects/data/models/admin_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/blocnet_search_delegate.dart';
import 'package:blocnet/features/projects/presentation/widgets/filter_bottom_sheet/filter_bottom_sheet.dart';
import 'package:blocnet/screen/public_profile_screen.dart';
import 'package:blocnet/services/auth_store.dart';
import 'package:blocnet/services/notifications_store.dart';
import 'package:blocnet/services/updates_store.dart';
import 'package:blocnet/services/projects_store.dart';
import 'package:flutter/material.dart';
import 'package:blocnet/app/typography.dart';
import 'package:provider/provider.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    required this.title,
    this.backButton = true,
    this.showFilter = true,
    this.showSearch = true,
    this.showSpaceSwitcher = false,
    this.showNotificationBell = false,
    this.showProfileShortcut = false,
    this.showProfileAvatarLeading = false,
    this.actions = const [],
  });

  final String title;
  final bool backButton;
  final bool showFilter;
  final bool showSearch;

  /// Show the User/Hunter space toggle pill (only renders for eligible roles).
  final bool showSpaceSwitcher;

  /// Show notification bell with badge in the app bar.
  final bool showNotificationBell;
  final bool showProfileShortcut;
  final bool showProfileAvatarLeading;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);
    final showBack = backButton && navigator.canPop();
    final showSpaceSwitcherInProfile = showSpaceSwitcher && title == 'Profile';
    final showLeadingProfile = showProfileAvatarLeading && !showBack;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgBase,
        border: Border(
          bottom: BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: SizedBox(
            height: kToolbarHeight,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: 44,
                    child: showBack
                        ? _AppBarIconButton(
                            icon: Icons.arrow_back_rounded,
                            onTap: () {
                              if (navigator.canPop()) {
                                navigator.pop();
                              } else {
                                navigator.pushNamedAndRemoveUntil(
                                  AppRoutes.main,
                                  (Route<dynamic> route) => false,
                                );
                              }
                            },
                          )
                        : showLeadingProfile
                            ? const _ProfileAvatarButton()
                            : const SizedBox.shrink(),
                  ),
                ),
                Center(
                  child: Text(
                    title,
                    style: AppTypography.custom(
                      color: AppColors.textPrimary,
                      size: 17,
                      weight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...actions,
                      if (showSpaceSwitcherInProfile) ...[
                        const SizedBox(width: 6),
                        const SpaceSwitcher(),
                      ],
                      if (showSearch) ...[
                        const SizedBox(width: 6),
                        _AppBarIconButton(
                          icon: Icons.search_rounded,
                          onTap: () {
                            showSearchDialog(context);
                          },
                        ),
                      ],
                      if (showNotificationBell) ...[
                        const SizedBox(width: 6),
                        _NotificationBellButton(),
                      ],
                      if (showProfileShortcut) ...[
                        const SizedBox(width: 6),
                        _AppBarIconButton(
                          icon: Icons.person_outline_rounded,
                          onTap: () {
                            Navigator.of(context).pushNamed(AppRoutes.profile);
                          },
                        ),
                      ],
                      if (showFilter) ...[
                        const SizedBox(width: 6),
                        _AppBarIconButton(
                          icon: Icons.tune_rounded,
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              isDismissible: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => FilterBottomSheet(),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void showSearchDialog(BuildContext context) {
    _openSearch(context);
  }

  @override
  Size get preferredSize {
    // Include the status bar (top safe area) height so the Scaffold
    // reserves the full space and the app bar content is not clipped.
    final topPadding = WidgetsBinding
            .instance.platformDispatcher.views.first.padding.top /
        WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
    return Size.fromHeight(kToolbarHeight + topPadding);
  }
}

Future<void> _openSearch(BuildContext context) async {
  final selected = await showSearch<Admin?>(
    context: context,
    delegate: BlocnetSearchDelegate(
      projects: context.read<ProjectsStore>().projects,
      posts: context.read<UpdatesStore>().posts,
    ),
  );

  if (selected == null || !context.mounted) {
    return;
  }

  await PublicProfileScreen.showSheet(context, selected);
}

// ─────────────────────────────────────────────────────────────────────────────
// Icon button — rounded square, 38×38
// ─────────────────────────────────────────────────────────────────────────────

class _AppBarIconButton extends StatelessWidget {
  const _AppBarIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSubtle, width: 1),
        ),
        child: Icon(icon, color: AppColors.textSecondary, size: 18),
      ),
    );
  }
}

class _ProfileAvatarButton extends StatelessWidget {
  const _ProfileAvatarButton();

  String _initials(AuthStore authStore) {
    final displayName = authStore.displayName?.trim() ?? '';
    if (displayName.isEmpty) return '';

    final parts = displayName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '';

    final first = parts.first.substring(0, 1).toUpperCase();
    final second =
        parts.length > 1 ? parts.last.substring(0, 1).toUpperCase() : '';
    return '$first$second';
  }

  @override
  Widget build(BuildContext context) {
    final authStore = context.watch<AuthStore>();
    final avatarUrl = authStore.avatarUrl?.trim() ?? '';
    final hasAvatar = avatarUrl.isNotEmpty;
    final initials = _initials(authStore);

    Widget fallbackAvatar() {
      if (initials.isNotEmpty) {
        return Text(
          initials,
          style: AppTypography.custom(
            color: AppColors.textPrimary,
            size: 12,
            weight: FontWeight.w700,
          ),
        );
      }
      return Icon(
        Icons.person_rounded,
        color: AppColors.textSecondary,
        size: 18,
      );
    }

    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed(AppRoutes.profile);
      },
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.borderSubtle, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: hasAvatar
            ? Image.network(
                avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(child: fallbackAvatar()),
              )
            : Center(child: fallbackAvatar()),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notification bell button with unread badge
// ─────────────────────────────────────────────────────────────────────────────

class _NotificationBellButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final unreadCount = context.watch<NotificationsStore>().unreadCount;

    return GestureDetector(
      onTap: () {
        // Navigate to notifications screen
        Navigator.of(context).pushNamed(AppRoutes.notifications);
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.bgElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderSubtle, width: 1),
            ),
            child: Icon(
              unreadCount > 0
                  ? Icons.notifications_rounded
                  : Icons.notifications_outlined,
              color: unreadCount > 0
                  ? AppColors.primary400
                  : AppColors.textSecondary,
              size: 18,
            ),
          ),
          if (unreadCount > 0)
            Positioned(
              top: -3,
              right: -3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.bgBase, width: 1.5),
                ),
                child: Text(
                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                  style: AppTypography.custom(
                    color: Colors.white,
                    size: 8,
                    weight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
