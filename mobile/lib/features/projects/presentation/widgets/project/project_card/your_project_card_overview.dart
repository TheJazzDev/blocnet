import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/follow_bottom_sheet/follow_bottom_sheet.dart';
import 'package:flutter/material.dart';

import '../../labels/primary_label.dart';
import '../../update/shared/update_project_logo.dart';

class YourProjectCardOverview extends StatefulWidget {
  const YourProjectCardOverview({required this.project, super.key});

  final Project project;

  @override
  State<YourProjectCardOverview> createState() =>
      _YourProjectCardOverviewState();
}

class _YourProjectCardOverviewState extends State<YourProjectCardOverview> {
  void _showOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      barrierColor: Colors.transparent,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).pop(),
          child: FollowBottomSheet(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        UpdateProjectLogo(logoUrl: widget.project.logo, size: 44),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PrimaryLabel(primaryTag: widget.project.primaryTag),
              const SizedBox(height: 4),
              Text(
                widget.project.name,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontFamily: 'Geist',
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _showOptions,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.bgElevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderSubtle, width: 1),
            ),
            child: Icon(
              Icons.more_horiz,
              size: 16,
              color: AppColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}
