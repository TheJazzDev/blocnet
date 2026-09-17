import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:flutter/material.dart';

/// Rows sitting in one flat bordered card, separated by hairlines.
///
/// ```dart
/// AppRowGroup(children: [
///   AppListRow(icon: Icons.person_outline, title: 'Account', onTap: open),
///   AppListRow(icon: Icons.lock_outline, title: 'Security', onTap: open),
/// ])
/// ```
class AppRowGroup extends StatelessWidget {
  const AppRowGroup({super.key, required this.children});

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
              if (i > 0) const AppHairline(),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// A 1px divider between rows or blocks inside a card.
class AppHairline extends StatelessWidget {
  const AppHairline({super.key, this.indent = 0});

  final double indent;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: indent,
      color: AppColors.borderSubtle,
    );
  }
}
