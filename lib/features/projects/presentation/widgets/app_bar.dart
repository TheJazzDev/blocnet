import 'package:blocknet/app/theme.dart';
import 'package:blocknet/features/projects/presentation/widgets/dot_divider.dart';
import 'package:blocknet/features/projects/presentation/widgets/filter_bottom_sheet/filter_bottom_sheet.dart';
import 'package:blocknet/shared/styled/text.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

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
            icon: Icons.notifications_outlined,
            onPressed: () {
              Navigator.pushNamed(context, '/notifications');
            },
          ),
          DotDivider(8),
          _buildIconButton(
            icon: Icons.search,
            onPressed: () {},
          ),
          DotDivider(8),
          _buildIconButton(
            icon: Symbols.page_info,
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
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

  Widget _buildIconButton(
      {required IconData icon, required VoidCallback onPressed}) {
    return Container(
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

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
