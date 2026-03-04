import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:flutter/material.dart';

class CommunityDiscussionNoPostView extends StatelessWidget {
  const CommunityDiscussionNoPostView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: const CustomAppBar(
        title: 'Post Discussion',
        backButton: true,
        showSearch: false,
        showFilter: false,
      ),
      body: Center(
        child: Text(
          'No post selected.',
          style: AppTypography.custom(
            color: AppColors.textMuted,
            size: 14,
            weight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
