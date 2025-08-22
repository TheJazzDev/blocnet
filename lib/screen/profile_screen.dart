import 'package:blocnet/shared/styles/app_text_styles.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: StyledBodyText400(
        'Profile Screen Welcomes You!',
      ),
    );
  }
}
