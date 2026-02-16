import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/features/projects/data/models/priority_model.dart';
import 'package:blocnet/shared/styles/app_text_styles.dart';
import 'package:blocnet/shared/utils/get_timestamp.dart';
import 'package:flutter/material.dart';

import '../../update/update_details/update_details_dialog.dart';

class YourProjectCardUpdate extends StatelessWidget {
  const YourProjectCardUpdate({required this.post, super.key});

  final Update post;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Dismiss',
        pageBuilder: (context, animation, secondaryAnimation) {
          return UpdateDetailsDialog(id: post.id);
        },
        transitionDuration: const Duration(milliseconds: 300),
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          color: post.priority == Priority.high
              ? AppColors.error900
              : post.priority == Priority.mid
                  ? AppColors.warning900
                  : AppColors.darkGrey200,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: SizedBox(
                height: 54,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StyledBodyText500(getTimeStamp(post.createdAt), size: 10),
                    const SizedBox(height: 4),
                    StyledBodyText600(post.title, size: 12),
                  ],
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.only(left: 24),
              child: Icon(
                Icons.keyboard_arrow_right,
                color: AppColors.darkGrey600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
