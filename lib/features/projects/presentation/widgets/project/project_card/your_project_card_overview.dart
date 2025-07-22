import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/follow_bottom_sheet/follow_bottom_sheet.dart';
import 'package:blocnet/shared/styles/app_text_styles.dart';
import 'package:flutter/material.dart';

import '../../post/shared/post_project_logo.dart';

class YourProjectCardOverview extends StatefulWidget {
  const YourProjectCardOverview({required this.project, super.key});

  final Project project;

  @override
  State<YourProjectCardOverview> createState() =>
      _YourProjectCardOverviewState();
}

class _YourProjectCardOverviewState extends State<YourProjectCardOverview> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PostProjectLogo(logoUrl: widget.project.logo, size: 52),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StyledBodyText500(widget.project.primaryTag.toString()),
              SizedBox(width: 4),
              StyledBodyText700(widget.project.name),
            ],
          ),
        ),
        SizedBox(width: 12),
        IconButton(
          style: IconButton.styleFrom(
            backgroundColor: AppColors.darkGrey200,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          icon: const Icon(Icons.more_vert),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              isDismissible: false,
              barrierColor: Colors.transparent,
              backgroundColor: Colors.transparent,
              builder: (context) {
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: FollowBottomSheet(),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
