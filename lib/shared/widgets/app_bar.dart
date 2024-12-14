import 'package:blocknet/app/app_theme.dart';
import 'package:blocknet/shared/styles/text.dart';
import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: AppBar(
        title: StyledTitleLarge(title),
        centerTitle: false,
        actions: [
          _buildIconButton(
            icon: Icons.notifications_on_outlined,
            onPressed: () {},
          ),
          _buildDivider(),
          _buildIconButton(
            icon: Icons.search,
            onPressed: () {},
          ),
          _buildDivider(),
          _buildIconButton(
            icon: Icons.tune,
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(
      {required IconData icon, required VoidCallback onPressed}) {
    return Container(
      // padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.darkGrey100,
        borderRadius: BorderRadius.circular(100),
      ),
      child: IconButton(
        style: IconButton.styleFrom(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: Icon(icon, color: AppColors.darkGrey500),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildDivider() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(8),
        width: 4,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.darkGrey200,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
