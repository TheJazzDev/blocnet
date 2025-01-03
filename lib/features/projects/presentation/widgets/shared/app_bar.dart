import 'package:blocknet/constants/app_routes.dart';
import 'package:blocknet/features/projects/presentation/widgets/dividers/dot_divider.dart';
import 'package:blocknet/features/projects/presentation/widgets/filter_bottom_sheet/filter_bottom_sheet.dart';
import 'package:blocknet/shared/styles/app_text_styles.dart';
import 'package:blocknet/shared/widgets/custom_icon_button.dart';
import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    required this.title,
    this.backButton = true,
  });

  final String title;
  final bool backButton;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: AppBar(
        title: StyledTitleLarge(title),
        centerTitle: false,
        automaticallyImplyLeading: backButton,
        actions: [
          CustomIconButton(
            svgAsset: "assets/icons/notification.svg",
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.notifications);
            },
          ),
          DotDivider(8),
          CustomIconButton(
            svgAsset: "assets/icons/search.svg",
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.discover);
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
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 24);
}
