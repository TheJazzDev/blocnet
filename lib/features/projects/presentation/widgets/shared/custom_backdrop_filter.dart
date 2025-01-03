import 'dart:ui';
import 'package:flutter/material.dart';

class CustomBackdropFilter extends StatelessWidget {
  const CustomBackdropFilter({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).pop();
        },
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(color: Color(0x80000000)),
        ),
      ),
    );
  }
}
