import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/projects/presentation/widgets/dividers/dot_divider.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/blocnet_search_delegate.dart';
import 'package:blocnet/features/projects/presentation/widgets/filter_bottom_sheet/filter_bottom_sheet.dart';
import 'package:blocnet/services/notifications_store.dart';
import 'package:blocnet/services/updates_store.dart';
import 'package:blocnet/services/projects_store.dart';
import 'package:blocnet/shared/styles/app_text_styles.dart';
import 'package:blocnet/shared/widgets/custom_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key, required this.title, this.backButton = true});

  final String title;
  final bool backButton;

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);
    final showBack = backButton && navigator.canPop();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: AppBar(
        title: StyledTitleLarge(title),
        centerTitle: false,
        automaticallyImplyLeading: false,
        leading: showBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
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
            : null,
        actions: [
          _NotificationActionButton(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.notifications);
            },
          ),
          DotDivider(8),
          CustomIconButton(
            svgAsset: "assets/icons/search.svg",
            onPressed: () {
              showSearch<void>(
                context: context,
                delegate: BlocnetSearchDelegate(
                  projects: context.read<ProjectsStore>().projects,
                  posts: context.read<UpdatesStore>().posts,
                ),
              );
            },
          ),
          DotDivider(8),
          CustomIconButton(
            svgAsset: "assets/icons/filter.svg",
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                isDismissible: true,
                backgroundColor: Colors.transparent,
                builder: (context) {
                  return FilterBottomSheet();
                },
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 2);
}

class _NotificationActionButton extends StatelessWidget {
  const _NotificationActionButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final unreadCount = context.watch<NotificationsStore>().unreadCount;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CustomIconButton(
          svgAsset: "assets/icons/notification.svg",
          onPressed: onPressed,
        ),
        if (unreadCount > 0)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
      ],
    );
  }
}
