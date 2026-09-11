import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/features/tips/data/models/tip_models.dart';
import 'package:blocnet/features/tips/presentation/widgets/tip_hunter_sheet.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Full-width "Tip Hunter" CTA shown under an update's body.
///
/// Renders nothing when the update has no author or when the viewer is the
/// author (you cannot tip yourself).
class UpdateTipHunterButton extends StatelessWidget {
  const UpdateTipHunterButton({super.key, required this.post});

  final Update post;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();
    final recipientUserId = post.adminId.toString().trim();
    if (recipientUserId.isEmpty) {
      return const SizedBox.shrink();
    }

    final isSelf = auth.userId != null && auth.userId == recipientUserId;
    if (isSelf) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          TipHunterSheet.show(
            context,
            recipient: TipRecipient(
              userId: recipientUserId,
              username: post.admin?.username,
              displayName: post.admin?.name,
              avatarUrl: post.admin?.imageUrl,
              isHunterHint: true,
            ),
            contextType: 'update',
            contextId: post.id.toString(),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary500,
          foregroundColor: Colors.black,
          minimumSize: const Size.fromHeight(44),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.mdValue),
          ),
        ),
        icon: const Icon(Icons.volunteer_activism_rounded, size: AppIcon.md),
        label: const Text('Tip Hunter'),
      ),
    );
  }
}
