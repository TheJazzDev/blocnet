import 'dart:math';
import 'package:blocknet/app/app_theme.dart';
import 'package:blocknet/features/projects/data/models/post.dart';
import 'package:blocknet/features/projects/presentation/widgets/primary_label.dart';
import 'package:blocknet/features/projects/presentation/widgets/secondary_label.dart';
import 'package:blocknet/features/projects/presentation/widgets/priority_label.dart';
import 'package:blocknet/shared/styles/text.dart';
import 'package:blocknet/shared/utils/format_date.dart';
import 'package:flutter/material.dart';

class PostCard extends StatefulWidget {
  const PostCard(
    this.post, {
    super.key,
  });

  final Post post;

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  int hiddenCount = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.darkGrey200,
        borderRadius: const BorderRadius.all(Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      margin: const EdgeInsets.only(top: 8, left: 16, bottom: 4),
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
          const SizedBox(width: 8),
          StyledHeading2(widget.post.projectTitle),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: AppColors.darkGrey100,
        borderRadius: const BorderRadius.all(Radius.circular(24)),
      ),
      child: Column(
        children: [
          _buildTagRow(),
          const SizedBox(height: 16),
          _buildPostDetails(),
        ],
      ),
    );
  }

  Widget _buildTagRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        const tagWidth = 120;
        final maxTags = (availableWidth / tagWidth).floor();

        hiddenCount = widget.post.secondaryTags.length > maxTags
            ? widget.post.secondaryTags.length - maxTags
            : 0;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Primary tag
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PrimaryLabel(widget.post.primaryTag),
                const SizedBox(width: 8),
                _buildDivider(25),
                const SizedBox(width: 8),
              ],
            ),

            // Secondary tags
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: widget.post.secondaryTags.take(maxTags).map((tag) {
                  return Container(
                    padding: const EdgeInsets.only(right: 4),
                    child: SecondaryLabel(tag),
                  );
                }).toList(),
              ),
            ),

            // Hidden tags count
            if (hiddenCount > 0)
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Container(
                  // margin: const EdgeInsets.only(left: 4),
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.darkGrey200,
                    borderRadius: const BorderRadius.all(Radius.circular(20)),
                  ),
                  child: StyledBodyText('+$hiddenCount'),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildPostDetails() {
    return Row(
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
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                widget.post.logoUrl,
                width: 40,
                height: 40,
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StyledTitleSmall(widget.post.title),
              const SizedBox(height: 8),
              StyledBodyText(widget.post.description),
              const SizedBox(height: 16),
              Row(
                children: [
                  StyledBodyTextFade(
                      formatDateWithSuffix(widget.post.createdAt)),
                  const SizedBox(width: 12),
                  _buildDivider(22),
                  const SizedBox(width: 4),
                  _buildDivider(22),
                  const SizedBox(width: 12),
                  PriorityLabel(widget.post.priority),
                ],
              ),
            ],
          ),
        ),
      ],
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
