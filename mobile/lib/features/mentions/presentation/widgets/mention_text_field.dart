import 'package:flutter/material.dart';
import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/mentions/data/models/mention_user_model.dart';
import 'package:blocnet/features/mentions/data/repositories/mentions_repository.dart';

class MentionTextField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? hintText;
  final int? maxLines;
  final int? minLines;
  final MentionsRepository mentionsRepository;
  final ValueChanged<String>? onChanged;

  const MentionTextField({
    super.key,
    required this.controller,
    required this.mentionsRepository,
    this.focusNode,
    this.hintText,
    this.maxLines,
    this.minLines,
    this.onChanged,
  });

  @override
  State<MentionTextField> createState() => _MentionTextFieldState();
}

class _MentionTextFieldState extends State<MentionTextField> {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  List<MentionUserModel> _suggestions = [];
  bool _isSearching = false;
  String _currentMentionQuery = '';
  int _mentionStartPosition = -1;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _removeOverlay();
    super.dispose();
  }

  void _onTextChanged() {
    final text = widget.controller.text;
    final selection = widget.controller.selection;

    if (!selection.isValid || selection.baseOffset < 0) {
      _removeOverlay();
      return;
    }

    final cursorPosition = selection.baseOffset;

    // Find the last @ before cursor
    final textBeforeCursor = text.substring(0, cursorPosition);
    final lastAtIndex = textBeforeCursor.lastIndexOf('@');

    if (lastAtIndex == -1) {
      _removeOverlay();
      return;
    }

    // Check if there's a space between @ and cursor (if so, stop showing suggestions)
    final textAfterAt = textBeforeCursor.substring(lastAtIndex + 1);
    if (textAfterAt.contains(' ') || textAfterAt.contains('\n')) {
      _removeOverlay();
      return;
    }

    // Extract the query after @
    final query = textAfterAt;

    if (query.isEmpty) {
      // Just typed @, show empty overlay or hide
      _removeOverlay();
      return;
    }

    _mentionStartPosition = lastAtIndex;
    _currentMentionQuery = query;
    _searchUsers(query);

    if (widget.onChanged != null) {
      widget.onChanged!(text);
    }
  }

  Future<void> _searchUsers(String query) async {
    if (_isSearching) return;

    setState(() {
      _isSearching = true;
    });

    try {
      final users = await widget.mentionsRepository.searchUsers(query, limit: 5);

      if (mounted) {
        setState(() {
          _suggestions = users;
          _isSearching = false;
        });

        if (users.isNotEmpty) {
          _showOverlay();
        } else {
          _removeOverlay();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _suggestions = [];
        });
      }
    }
  }

  void _showOverlay() {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - 32,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 50),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            color: AppColors.bgSurface,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.borderSubtle,
                  width: 1,
                ),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                shrinkWrap: true,
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  final user = _suggestions[index];
                  return _buildSuggestionItem(user);
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  Widget _buildSuggestionItem(MentionUserModel user) {
    return InkWell(
      onTap: () => _insertMention(user),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary400.withValues(alpha: 0.2),
              backgroundImage: user.avatarUrl != null
                  ? NetworkImage(user.avatarUrl!)
                  : null,
              child: user.avatarUrl == null
                  ? Text(
                      user.username[0].toUpperCase(),
                      style: AppTypography.custom(
                        color: AppColors.primary400,
                        size: 12,
                        weight: FontWeight.w600,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName ?? user.username,
                    style: AppTypography.custom(
                      color: AppColors.textPrimary,
                      size: 13,
                      weight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '@${user.username}',
                    style: AppTypography.custom(
                      color: AppColors.textMuted,
                      size: 11,
                      weight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _insertMention(MentionUserModel user) {
    final text = widget.controller.text;
    final mentionText = '@${user.username} ';

    // Replace from @ to cursor with the mention
    final newText = text.substring(0, _mentionStartPosition) +
        mentionText +
        text.substring(widget.controller.selection.baseOffset);

    final newCursorPosition = _mentionStartPosition + mentionText.length;

    widget.controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursorPosition),
    );

    _removeOverlay();

    if (widget.onChanged != null) {
      widget.onChanged!(newText);
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {
      _suggestions = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        maxLines: widget.maxLines,
        minLines: widget.minLines,
        style: AppTypography.custom(
          color: AppColors.textPrimary,
          size: 14,
          weight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: AppTypography.custom(
            color: AppColors.textMuted,
            size: 14,
            weight: FontWeight.w400,
          ),
          filled: true,
          fillColor: AppColors.bgBase,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: AppColors.borderSubtle,
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: AppColors.borderSubtle,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: AppColors.primary400,
              width: 1.5,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}
