import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/profile/presentation/widgets/common/profile_inline_state.dart';
import 'package:blocnet/features/profile/presentation/widgets/common/profile_row_group.dart';
import 'package:blocnet/features/profile/presentation/widgets/profile_body/tabs/profile_tab_list.dart';
import 'package:blocnet/features/profile/presentation/widgets/profile_body/tabs/saved_update_row.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/detail_dialogs.dart';
import 'package:blocnet/services/projects/update_reactions_store.dart';
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

  @override
  Widget build(BuildContext context) {
    final reactions = context.watch<UpdateReactionsStore>();
    final bookmarks = reactions.savedUpdates;

    if ((reactions.isLoadingSaved || !reactions.hasLoadedSaved) &&
        bookmarks.isEmpty &&
        reactions.savedError == null) {
      return Padding(
        padding: const EdgeInsets.all(AppSpace.xl),
        child: Center(
          child: SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(
              color: widget.accent,
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }

    if (bookmarks.isEmpty && reactions.savedError != null) {
      // Saying "nothing saved" here would be false; the list did not load.
      return ProfileRowGroup(
        children: [
          ProfileInlineState(
            icon: Icons.cloud_off_rounded,
            title: 'Could not load your saved updates',
            actionLabel: 'Retry',
            onAction: reactions.refreshSaved,
          ),
        ],
      );
    }

    if (bookmarks.isEmpty) {
      return const ProfileRowGroup(
        children: [
          ProfileInlineState(
            icon: Icons.bookmark_border_rounded,
            title: 'Bookmark updates to save them here',
          ),
        ],
      );
    }

    return ProfileTabList(
      itemCount: bookmarks.length,
      itemBuilder: (context, index) {
        final update = bookmarks[index];
        return SavedUpdateRow(
          key: ValueKey('saved-${update.id}'),
          update: update,
          onOpen: () => showUpdateDetailsDialog(context, update.id),
          onRemove: () => _remove(update),
        );
      },
    );
  }
}
