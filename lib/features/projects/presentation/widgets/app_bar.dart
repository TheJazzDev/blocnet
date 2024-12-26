import 'package:blocknet/app/theme.dart';
import 'package:blocknet/constants/app_routes.dart';
import 'package:blocknet/features/projects/presentation/widgets/dot_divider.dart';
import 'package:blocknet/features/projects/presentation/widgets/filter_bottom_sheet/filter_bottom_sheet.dart';
import 'package:blocknet/shared/styles/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: AppBar(
        title: StyledTitleLarge(title),
        centerTitle: false,
        actions: [
          _buildIconButton(
            svgAsset: "assets/icons/notification.svg",
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.notifications);
            },
          ),
          DotDivider(8),
          _buildIconButton(
            svgAsset: "assets/icons/search.svg",
            onPressed: () {},
          ),
          DotDivider(8),
          _buildIconButton(
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

  Widget _buildIconButton({
    IconData? iconData,
    String? svgAsset,
    required VoidCallback onPressed,
  }) {
    assert(iconData != null || svgAsset != null,
        'Either iconData or svgAsset must be provided');
    return IconButton(
      style: IconButton.styleFrom(
        backgroundColor: AppColors.darkGrey100,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: svgAsset != null
          ? SvgPicture.asset(
              svgAsset,
              width: 20,
              height: 20,
            )
          : Icon(iconData, size: 26, color: AppColors.darkGrey500),
      onPressed: onPressed,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 24);
}
