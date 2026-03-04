import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/projects/data/models/priority_model.dart';
import 'package:blocnet/services/projects/update_bookmarks_store.dart';
import 'package:blocnet/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:blocnet/features/projects/presentation/widgets/labels/priority_label.dart';

class UpdateDetailsHeader extends StatefulWidget {
  const UpdateDetailsHeader({
    required this.priority,
    required this.updateId,
    this.title,
    this.showPriority = true,
    super.key,
  });

  final Priority priority;
  final String updateId;
  final String? title;
  final bool showPriority;

  @override
  State<UpdateDetailsHeader> createState() => _UpdateDetailsHeaderState();
}

class _UpdateDetailsHeaderState extends State<UpdateDetailsHeader> {
  bool _isBookmarked = false;
  bool _isLoadingBookmark = false;

  @override
  void initState() {
    super.initState();
    _loadBookmarkState();
  }

  Future<void> _loadBookmarkState() async {
    final bookmarked =
        await UpdateBookmarksStore.isBookmarked(widget.updateId);
    if (!mounted) return;
    setState(() {
      _isBookmarked = bookmarked;
    });
  }

  Future<void> _toggleBookmark() async {
    if (_isLoadingBookmark) return;

    setState(() => _isLoadingBookmark = true);
    try {
      final bookmarked = await UpdateBookmarksStore.toggle(widget.updateId);
      if (!mounted) return;
      setState(() => _isBookmarked = bookmarked);
      AppSnackbar.showSuccess(
        context,
        bookmarked ? 'Update bookmarked' : 'Bookmark removed',
      );
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.showError(context, 'Could not update bookmark');
    } finally {
      if (mounted) {
        setState(() => _isLoadingBookmark = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final headerTitle = widget.title?.trim();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _HeaderIconButton(
            icon: Icons.close,
            onTap: () => Navigator.of(context).pop(),
          ),
          if (headerTitle != null && headerTitle.isNotEmpty) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                headerTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ] else ...[
            const Spacer(),
            if (widget.showPriority) PriorityLabel(priority: widget.priority),
            const Spacer(),
          ],
          _HeaderIconButton(
            icon: _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border,
            onTap: _toggleBookmark,
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderSubtle, width: 1),
        ),
        child: Icon(icon, size: 18, color: AppColors.textMuted),
      ),
    );
  }
}
