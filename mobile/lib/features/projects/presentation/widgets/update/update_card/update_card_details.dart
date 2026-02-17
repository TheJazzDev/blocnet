import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/shared/utils/format_date_utils.dart';
import 'package:flutter/material.dart';
import '../shared/update_project_logo.dart';

class UpdateCardDetails extends StatelessWidget {
  const UpdateCardDetails({
    required this.post,
    this.miniCard = false,
    super.key,
  });

  final Update post;
  final bool miniCard;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UpdateProjectLogo(logoUrl: post.project?.logo ?? '', size: 36),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                post.title,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: miniCard ? 13 : 14,
                  fontFamily: 'Geist',
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 5),
              // Description
              Text(
                post.description,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontFamily: 'Geist',
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              // Date
              Text(
                formatDateWithSuffix(post.createdAt),
                style: TextStyle(
                  color: AppColors.textFaint,
                  fontSize: 11,
                  fontFamily: 'Geist',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
