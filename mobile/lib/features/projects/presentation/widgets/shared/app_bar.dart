import 'package:blocnet/app/theme.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/blocnet_search_delegate.dart';
import 'package:blocnet/features/projects/presentation/widgets/filter_bottom_sheet/filter_bottom_sheet.dart';
import 'package:blocnet/services/notifications_store.dart';
import 'package:blocnet/services/updates_store.dart';
import 'package:blocnet/services/projects_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    required this.title,
    this.backButton = true,
    this.showFilter = true,
  });

  final String title;
  final bool backButton;
  final bool showFilter;

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);
    final showBack = backButton && navigator.canPop();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        border: const Border(
          bottom: BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: kToolbarHeight,
          child: Row(
            children: [
              // Back button or left spacer
              if (showBack)
                _AppBarIconButton(
                  icon: Icons.arrow_back_ios_new_rounded,
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
              else
                const SizedBox(width: 12),

              // Title
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Geist',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Action buttons
              _NotificationButton(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.notifications),
              ),
              const SizedBox(width: 4),
              _AppBarIconButton(
                icon: Icons.search_rounded,
                onTap: () {
                  showSearch<void>(
                    context: context,
                    delegate: BlocnetSearchDelegate(
                      projects: context.read<ProjectsStore>().projects,
                      posts: context.read<UpdatesStore>().posts,
                    ),
                  );
                },
              ),
              if (showFilter) ...[
                const SizedBox(width: 4),
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
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 16);
}

// ─────────────────────────────────────────────────────────────────────────────
// Icon button (consistent 36×36 tap target)
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
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderSubtle, width: 1),
        ),
        child: Icon(icon, color: AppColors.textSecondary, size: 17),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notification button with unread dot
// ─────────────────────────────────────────────────────────────────────────────

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final unreadCount = context.watch<NotificationsStore>().unreadCount;

    return GestureDetector(
      onTap: onPressed,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.bgElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderSubtle, width: 1),
            ),
            child: Icon(
              Icons.notifications_outlined,
              color: unreadCount > 0
                  ? AppColors.teal400
                  : AppColors.textSecondary,
              size: 17,
            ),
          ),
          if (unreadCount > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.teal400,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.bgBase,
                    width: 1.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
