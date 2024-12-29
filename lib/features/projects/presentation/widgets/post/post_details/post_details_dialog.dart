import 'package:blocknet/app/theme.dart';
import 'package:blocknet/features/projects/data/models/post_model.dart';
import 'package:blocknet/features/projects/data/models/primary_tag_model.dart';
import 'package:blocknet/features/projects/data/services/post_by_id.dart';
import 'package:blocknet/features/projects/presentation/widgets/dividers/horizontal_divider.dart';
import 'package:flutter/material.dart';
import '../more_from/more_from_primary_tag.dart';
import '../more_from/more_from_project_name.dart';
import '../more_from/more_from_secondary_tags.dart';
import 'post_details_header.dart';
import 'post_details_info.dart';
import 'post_details_overview.dart';
import 'post_details_tags.dart';

class PostDetailsDialog extends StatefulWidget {
  const PostDetailsDialog({required this.postId, super.key});

  final String postId;

  @override
  State<PostDetailsDialog> createState() => _PostDetailsDialogState();
}

class _PostDetailsDialogState extends State<PostDetailsDialog> {
  late Post post;

  @override
  void initState() {
    super.initState();
    post = PostById.fetchPostById(widget.postId);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
              color: AppColors.darkGrey100,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              )),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Column(
              children: [
                PostDetailsHeader(priority: post.priority),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PostDetailsInfo(post: post),
                        const CustomHorizontalDivider(margin: 12),
                        PostDetailsTags(post),
                        const CustomHorizontalDivider(margin: 12),
                        PostDetailsOverview(content: post.content),
                        SizedBox(height: 40),
                        MoreFromProjectName(
                            projectId: post.project?.id ?? '',
                            projectTitle: post.project?.name ?? ''),
                        const CustomHorizontalDivider(margin: 16),
                        const SizedBox(height: 16),
                        MoreFromPrimaryTag(
                            primaryTag:
                                post.project?.primaryTag ?? PrimaryTag.none),
                        SizedBox(height: 8),
                        const CustomHorizontalDivider(margin: 16),
                        SizedBox(height: 8),
                        MoreFromSecondaryTags(post: post),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
