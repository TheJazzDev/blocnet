import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:flutter/material.dart';

/// One flat bordered card holding list rows, separated by hairlines.
class ProfileRowGroup extends StatelessWidget {
  const ProfileRowGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0)
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.borderSubtle,
                ),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}
