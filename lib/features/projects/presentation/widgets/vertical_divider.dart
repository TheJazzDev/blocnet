import 'package:blocknet/app/theme.dart';
import 'package:flutter/material.dart';

class CustomVerticalDivider extends StatelessWidget {
  const CustomVerticalDivider({
    required this.height,
    this.single = false,
    super.key,
  });

  final double height;
  final bool single;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: [
        _buildDivider(),
        if (!single) const SizedBox(width: 4),
        if (!single) _buildDivider(),
      ],
    );
  }

  // Reusable method to build the divider
  Widget _buildDivider() {
    return Container(
      width: 2,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.darkGrey200,
        shape: BoxShape.rectangle,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
    );
  }
}
