import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/projects/data/models/primary_tag_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/dividers/horizontal_divider.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/render_markdown_content.dart';
import 'package:blocnet/services/posts_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../more_from/more_from_primary_tag.dart';
import '../../shared/more_from_project_name.dart';
import '../more_from/more_from_secondary_tags.dart';
import 'post_details_header.dart';
import 'post_details_info.dart';
import 'post_details_tags.dart';

class PostDetailsDialog extends StatelessWidget {
  const PostDetailsDialog({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context) {
    final postStore = Provider.of<PostsStore>(context);
    final post = postStore.getPostById(id);

    if (post.project == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final moreFromProjectName = post.project?.posts ?? [];

    return SafeArea(
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.darkGrey100,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Column(
              children: [
                PostDetailsHeader(priority: post.priority),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        PostDetailsInfo(post: post),
                        const CustomHorizontalDivider(margin: 12),
                        PostDetailsTags(post),
                        const CustomHorizontalDivider(margin: 12),
                        RenderMarkdownContent(content: post.content),
                        const SizedBox(height: 40),
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
                        const SizedBox(height: 8),
                        const CustomHorizontalDivider(margin: 16),
                        const SizedBox(height: 8),
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
