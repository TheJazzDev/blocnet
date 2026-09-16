import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/profile/presentation/widgets/profile_body/tabs/profile_tab_bar.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/features/projects/presentation/models/feed_view_mode.dart';
import 'package:blocnet/features/projects/presentation/widgets/update/update_details/update_details_dialog.dart';
import 'package:blocnet/services/core/feed_view_mode_store.dart';
import 'package:blocnet/services/projects/update_reactions_store.dart';
import 'package:blocnet/shared/utils/get_timestamp.dart';
import 'package:blocnet/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// "Saved" tab: updates the member saved, as the server holds them
/// (`GET /me/bookmarks/updates`), newest save first.
class ProfileSavedTab extends StatefulWidget {
  const ProfileSavedTab({super.key, required this.accent});

  final Color accent;

  @override
  State<ProfileSavedTab> createState() => _ProfileSavedTabState();
}

class _ProfileSavedTabState extends State<ProfileSavedTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Always re-read on open: saves made elsewhere (another device) count.
      context.read<UpdateReactionsStore>().refreshSaved();
    });
  }

  Future<void> _remove(Update update) async {
    try {
      await context.read<UpdateReactionsStore>().toggleBookmark(update);
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.showError(context, 'Could not update bookmark');
    }
  }

  void _openUpdate(Update update) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.72),
      pageBuilder: (context, _, __) => UpdateDetailsDialog(id: update.id),
      transitionDuration: const Duration(milliseconds: 280),
      transitionBuilder: (context, animation, _, child) {
        final curved =
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final reactions = context.watch<UpdateReactionsStore>();
    final isCardMode =
        context.watch<FeedViewModeStore>().mode == FeedViewMode.card;
    final bookmarks = reactions.savedUpdates;

    if ((reactions.isLoadingSaved || !reactions.hasLoadedSaved) &&
        bookmarks.isEmpty &&
        reactions.savedError == null) {
      return Center(
        child: CircularProgressIndicator(color: widget.accent, strokeWidth: 2),
      );
    }

    if (bookmarks.isEmpty && reactions.savedError != null) {
      // Saying "nothing saved" here would be false; the list did not load.
      return const ProfileTabEmptyState(
        icon: Icons.cloud_off_rounded,
        title: 'Could not load your saved updates',
        hint: 'Check your connection and open this tab again.',
      );
    }

    if (bookmarks.isEmpty) {
      return const ProfileTabEmptyState(
        icon: Icons.bookmark_add_outlined,
        title: 'Bookmark updates to save them here',
      );
    }

    return ListView.builder(
      primary: false,
      padding: const EdgeInsets.fromLTRB(
          AppSpace.lg, AppSpace.sm, AppSpace.lg, AppSpace.lg),
      itemCount: bookmarks.length,
      itemBuilder: (context, index) {
        final update = bookmarks[index];
        return ProfileTabTileFrame(
          isCardMode: isCardMode,
          showDivider: !isCardMode && index != bookmarks.length - 1,
          onTap: () => _openUpdate(update),
          child: _SavedUpdate(
            update: update,
            accent: widget.accent,
            isCardMode: isCardMode,
            onRemove: () => _remove(update),
          ),
        );
      },
    );
  }
}

class _SavedUpdate extends StatelessWidget {
  const _SavedUpdate({
    required this.update,
    required this.accent,
    required this.isCardMode,
    required this.onRemove,
  });

  final Update update;
  final Color accent;
  final bool isCardMode;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final gemName = update.project?.name ?? 'Gem';
    final preview = update.description.trim().isEmpty
        ? update.content.trim()
        : update.description.trim();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.smValue),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withValues(alpha: 0.2),
                accent.withValues(alpha: 0.08),
              ],
            ),
          ),
          child: Icon(
            Icons.auto_awesome_rounded,
            size: AppIcon.lg,
            color: AppColors.textFaint,
          ),
        ),
        const SizedBox(width: AppSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      update.title,
                      style: AppTypography.custom(
                        color: AppColors.textPrimary,
                        size: AppText.labelSize,
                        weight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Text(
                    getTimeStamp(update.createdAt),
                    style: AppTypography.custom(
                      color: AppColors.textFaint,
                      size: AppText.captionSize,
                      weight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.sm),
              Text(
                preview,
                style: AppTypography.custom(
                  color: AppColors.textMuted,
                  size: AppText.captionSize,
                  weight: FontWeight.w400,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpace.sm),
              Row(
                children: [
                  Text(
                    gemName,
                    style: AppTypography.custom(
                      color: AppColors.textFaint,
                      size: AppText.captionSize,
                      weight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onRemove,
                    behavior: HitTestBehavior.opaque,
                    child: Icon(
                      Icons.bookmark_remove_outlined,
                      size: AppIcon.sm,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (isCardMode) ...[
          const SizedBox(width: AppSpace.xs),
          Icon(
            Icons.chevron_right_rounded,
            size: AppIcon.md,
            color: AppColors.textFaint,
          ),
        ],
      ],
    );
  }
}
