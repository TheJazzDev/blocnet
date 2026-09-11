import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/features/projects/data/models/priority_model.dart';
import 'package:blocnet/shared/utils/get_timestamp.dart';
import 'package:flutter/material.dart';

import '../../update/update_details/update_details_dialog.dart';

class YourProjectCardUpdate extends StatelessWidget {
  const YourProjectCardUpdate({required this.post, super.key});

  final Update post;

  void _openDetails(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      pageBuilder: (context, animation, secondaryAnimation) {
        return UpdateDetailsDialog(id: post.id);
      },
      transitionDuration: const Duration(milliseconds: 320),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        );
      },
    );
  }

  Color get _priorityColor {
    if (post.priority == Priority.high) return AppColors.priorityHigh;
    if (post.priority == Priority.mid) return AppColors.priorityMid;
    return AppColors.priorityLow;
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _priorityColor;

    return GestureDetector(
      onTap: () => _openDetails(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpace.sm),
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(AppRadius.mdValue),
          border: Border.all(color: AppColors.borderSubtle, width: 1),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Priority accent bar
              Container(
                width: 3,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    bottomLeft: Radius.circular(10),
                  ),
                ),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpace.sm,
                    horizontal: AppSpace.md,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              post.title,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: AppText.labelSize,
                                fontFamily: 'Geist',
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppSpace.hair),
                            Text(
                              getTimeStamp(post.createdAt),
                              style: TextStyle(
                                color: AppColors.textFaint,
                                fontSize: AppText.captionSize,
                                fontFamily: 'Geist',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Icon(
                        Icons.chevron_right,
                        size: AppIcon.sm,
                        color: AppColors.textFaint,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
