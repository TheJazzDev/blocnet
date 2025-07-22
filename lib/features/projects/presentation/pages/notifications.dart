import 'package:blocnet/app/theme.dart';
import 'package:blocnet/shared/styles/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        backgroundColor: AppColors.darkGrey50,
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Symbols.mop, color: AppColors.darkGrey500),
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: const StyledBodyText(
          'All your notifications will be display here!!!',
        ),
      ),
    );
  }
}
