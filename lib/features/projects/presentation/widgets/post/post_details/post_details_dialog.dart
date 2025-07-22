import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/projects/data/dummy/dummy_posts.dart';
import 'package:blocnet/features/projects/data/models/post_model.dart';
import 'package:blocnet/features/projects/data/models/primary_tag_model.dart';
import 'package:blocnet/features/projects/data/services/post_by_id_service.dart';
import 'package:blocnet/features/projects/presentation/widgets/dividers/horizontal_divider.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/render_markdown_content.dart';
import 'package:flutter/material.dart';
import '../more_from/more_from_primary_tag.dart';
import '../../shared/more_from_project_name.dart';
import '../more_from/more_from_secondary_tags.dart';
import 'post_details_header.dart';
import 'post_details_info.dart';
import 'post_details_tags.dart';

class PostDetailsDialog extends StatefulWidget {
  const PostDetailsDialog({required this.postId, super.key});

  final String postId;

  @override
  State<PostDetailsDialog> createState() => _PostDetailsDialogState();
}

class _PostDetailsDialogState extends State<PostDetailsDialog> {
  late Post post;
  late List<Post> moreFromProjectName;

  @override
  void initState() {
    super.initState();
    post = PostByIdService.fetchPostById(widget.postId);

    setState(() {
      moreFromProjectName = dummyPosts
          .where((post) => post.projectId == post.  project?.id)
          .toList();
    });
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
            ),
          ),
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
                        RenderMarkdownContent(content: post.content),
                        SizedBox(height: 40),
                        MoreFromProjectName(
                          label: 'More from',
                          projectTitle: post.project?.name ?? '',
                          posts: moreFromProjectName,
                        ),
                        const CustomHorizontalDivider(margin: 16),
                        const SizedBox(height: 16),
                        MoreFromPrimaryTag(
                          primaryTag:
                              post.project?.primaryTag ?? PrimaryTag.none,
                        ),
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
