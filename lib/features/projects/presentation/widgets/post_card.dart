import 'dart:math';

import 'package:blocknet/app/app_theme.dart';
import 'package:blocknet/features/projects/data/models/primary_tag.dart';
import 'package:blocknet/features/projects/data/models/secondary_tag.dart';
import 'package:blocknet/features/projects/data/models/priority.dart';
import 'package:blocknet/features/projects/presentation/widgets/primary_label.dart';
import 'package:blocknet/features/projects/presentation/widgets/secondary_label.dart';
import 'package:blocknet/features/projects/presentation/widgets/priority_label.dart';
import 'package:blocknet/shared/styles/text.dart';
import 'package:blocknet/shared/utils/format_date.dart';
import 'package:flutter/material.dart';

class PostCard extends StatefulWidget {
  const PostCard({
    super.key,
    required this.projectTitle,
    required this.primaryTag,
    required this.secondaryTags,
    required this.logoUrl,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.priority,
  });

  final String projectTitle;
  final PrimaryTag primaryTag;
  final List<SecondaryTag> secondaryTags;
  final String logoUrl;
  final String title;
  final String description;
  final DateTime createdAt;
  final Priority priority;

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.darkGrey200,
        borderRadius: const BorderRadius.all(Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            margin: EdgeInsets.only(top: 8, left: 16, bottom: 4),
            decoration: BoxDecoration(
              color: AppColors.darkGrey100,
              border: Border.all(
                color: AppColors.darkGrey400,
              ),
              borderRadius: const BorderRadius.all(Radius.circular(40)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.style,
                  size: 24,
                  color: AppColors.darkGrey400,
                ),
                SizedBox(width: 8),
                StyledHeading2(widget.projectTitle),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            margin: EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: AppColors.darkGrey100,
              borderRadius: const BorderRadius.all(Radius.circular(24)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    PrimaryLabel(widget.primaryTag.toString()),
                    SizedBox(width: 8),
                    _buildDivider(25),
                    SizedBox(width: 8),
                    Row(
                      children: [
                        ...widget.secondaryTags.map((tag) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: SecondaryLabel(tag.toString()),
                          );
                        }),
                      ],
                    )
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          top: 2,
                          left: 5,
                          child: Transform.rotate(
                            angle: 6 * pi / 180,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.darkGrey300,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10)),
                              ),
                            ),
                          ),
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            widget.logoUrl,
                            width: 40,
                            height: 40,
                          ),
                        )
                      ],
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          StyledTitleSmall(
                            widget.title,
                          ),
                          SizedBox(height: 8),
                          StyledBodyText(
                            widget.description,
                          ),
                          SizedBox(height: 16),
                          Row(
                            children: [
                              StyledBodyTextFade(
                                  formatDateWithSuffix(widget.createdAt)),
                              SizedBox(width: 12),
                              _buildDivider(22),
                              SizedBox(width: 4),
                              _buildDivider(22),
                              SizedBox(width: 12),
                              PriorityLabel(widget.priority),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDivider(double height) {
    return Container(
      width: 2,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.darkGrey200,
        shape: BoxShape.rectangle,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
    );
  }
}
