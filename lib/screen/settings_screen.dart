import 'package:blocnet/shared/styles/app_text_styles.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: StyledBodyText400(
        'Settings Screen Welcomes You!',
      ),
    );
  }
}
