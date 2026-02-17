import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/update/shared/update_tag_row.dart';
import 'package:flutter/material.dart';
import 'package:blocnet/features/projects/presentation/widgets/labels/priority_label.dart';
import 'package:blocnet/features/projects/presentation/widgets/dividers/vertical_divider.dart';
import 'package:blocnet/shared/utils/format_date_utils.dart';

class MoreFromProjectNameUpdateCard extends StatelessWidget {
  const MoreFromProjectNameUpdateCard({required this.post, super.key});

  final Update post;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 295,
      height: 216,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        border: Border.all(color: AppColors.borderSubtle),
        borderRadius: const BorderRadius.all(Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UpdateTagRow(post: post, moreFrom: true),
          const SizedBox(height: 12),
          Text(
            post.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontFamily: 'Geist',
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              post.description,
              overflow: TextOverflow.ellipsis,
              maxLines: 3,
              style: TextStyle(
                color: AppColors.textFaint,
                fontSize: 12,
                fontFamily: 'Geist',
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                formatDateWithSuffix(post.createdAt),
                style: TextStyle(
                  color: AppColors.textFaint,
                  fontSize: 12,
                  fontFamily: 'Geist',
                ),
              ),
              const SizedBox(width: 12),
              CustomVerticalDivider(height: 20),
              const SizedBox(width: 12),
              PriorityLabel(priority: post.priority, miniCard: true),
            ],
          ),
        ],
      ),
    );
  }
}
