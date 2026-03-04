import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/projects/data/models/primary_tag_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/update/update_card/update_card.dart';
import 'package:blocnet/features/projects/presentation/widgets/labels/primary_label.dart';
import 'package:blocnet/services/projects/updates_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MoreFromUpdatePrimaryTag extends StatelessWidget {
  const MoreFromUpdatePrimaryTag({required this.primaryTag, super.key});

  final PrimaryTag primaryTag;

  @override
  Widget build(BuildContext context) {
    final postStore = Provider.of<UpdatesStore>(context);
    final morePosts = postStore.getUpdatesByPrimaryTag(primaryTag, context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'More From',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontFamily: 'Geist',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                PrimaryLabel(primaryTag: primaryTag),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        morePosts.isEmpty
            ? Text(
                'No updates available for this tag!',
                style: TextStyle(
                  color: AppColors.textFaint,
                  fontSize: 12,
                  fontFamily: 'Geist',
                ),
              )
            : Column(
                children: List.generate(
                  morePosts.length,
                  (index) => UpdateCard(post: morePosts[index], miniCard: true),
                ),
              ),
      ],
    );
  }
}
