import 'dart:ui';
import 'package:blocknet/app/app_theme.dart';
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
            onPressed: () {},
          ),
          _buildDivider(),
          _buildIconButton(
            icon: Icons.search,
            onPressed: () {},
          ),
          _buildDivider(),
          _buildIconButton(
            icon: Symbols.page_info,
            onPressed: () {
              showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  barrierColor: Colors.transparent,
                  builder: (context) {
                    return Stack(children: [
                      Positioned.fill(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                          child: Container(
                            color: Colors.black,
                          ),
                        ),
                      ),
                      FilterBottomSheet()
                    ]);
                  });
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
