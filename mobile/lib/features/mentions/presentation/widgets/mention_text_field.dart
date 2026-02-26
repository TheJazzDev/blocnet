import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/mentions/data/models/mention_user_model.dart';
import 'package:blocnet/features/mentions/data/repositories/mentions_repository.dart';
import 'package:blocnet/shared/widgets/app_avatar.dart';

class MentionHighlightTextController extends TextEditingController {
  static final RegExp _mentionRegex = RegExp(r'@([a-zA-Z0-9._-]+)');

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final baseStyle = style ?? const TextStyle();
    final mentionStyle = baseStyle.copyWith(
      color: AppColors.primary400,
      fontWeight: FontWeight.w600,
    );
    final text = value.text;

    if (!withComposing || !value.composing.isValid) {
      return TextSpan(
        style: baseStyle,
        children: _buildMentionSpans(text, baseStyle, mentionStyle),
      );
    }

    final composingStart = value.composing.start.clamp(0, text.length).toInt();
    final composingEnd =
        value.composing.end.clamp(composingStart, text.length).toInt();
    if (composingStart >= composingEnd) {
      return TextSpan(
        style: baseStyle,
        children: _buildMentionSpans(text, baseStyle, mentionStyle),
      );
    }

    return TextSpan(
      style: baseStyle,
      children: [
        ..._buildMentionSpans(
          text.substring(0, composingStart),
          baseStyle,
          mentionStyle,
        ),
        TextSpan(
          text: text.substring(composingStart, composingEnd),
          style: baseStyle.merge(
            const TextStyle(decoration: TextDecoration.underline),
          ),
        ),
        ..._buildMentionSpans(
          text.substring(composingEnd),
          baseStyle,
          mentionStyle,
        ),
      ],
    );
  }

  List<InlineSpan> _buildMentionSpans(
    String text,
    TextStyle defaultStyle,
    TextStyle mentionStyle,
  ) {
    if (text.isEmpty) return [TextSpan(text: text, style: defaultStyle)];

    final matches = _mentionRegex.allMatches(text);
    if (matches.isEmpty) {
      return [TextSpan(text: text, style: defaultStyle)];
    }

    final spans = <InlineSpan>[];
    var currentPosition = 0;

    for (final match in matches) {
      if (match.start > currentPosition) {
        spans.add(
          TextSpan(
            text: text.substring(currentPosition, match.start),
            style: defaultStyle,
          ),
        );
      }

      spans.add(
        TextSpan(
          text: match.group(0),
          style: mentionStyle,
        ),
      );

      currentPosition = match.end;
    }

    if (currentPosition < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(currentPosition),
          style: defaultStyle,
        ),
      );
    }

    return spans;
  }
}

class MentionTextField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? hintText;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final MentionsRepository mentionsRepository;
  final ValueChanged<String>? onChanged;
  final bool showFocusHighlight;

  const MentionTextField({
    super.key,
    required this.controller,
    required this.mentionsRepository,
    this.focusNode,
    this.hintText,
    this.maxLines,
    this.minLines,
    this.maxLength,
    this.onChanged,
    this.showFocusHighlight = true,
  });

  @override
  State<MentionTextField> createState() => _MentionTextFieldState();
}

class _MentionTextFieldState extends State<MentionTextField> {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  List<MentionUserModel> _suggestions = [];
  Timer? _searchDebounce;
  int _activeSearchToken = 0;
  int _mentionStartPosition = -1;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _searchDebounce?.cancel();
    _removeOverlay();
    super.dispose();
  }

  void _onTextChanged() {
    final text = widget.controller.text;
    final selection = widget.controller.selection;

    if (widget.onChanged != null) {
      widget.onChanged!(text);
    }

    if (!selection.isValid || selection.baseOffset < 0) {
      _removeOverlay(clearSuggestions: true);
      return;
    }

    final cursorPosition = selection.baseOffset;

    // Find the last @ before cursor
    final textBeforeCursor = text.substring(0, cursorPosition);
    final lastAtIndex = textBeforeCursor.lastIndexOf('@');

    if (lastAtIndex == -1) {
      _removeOverlay(clearSuggestions: true);
      return;
    }

    // Check if there's a space between @ and cursor (if so, stop showing suggestions)
    final textAfterAt = textBeforeCursor.substring(lastAtIndex + 1);
    if (textAfterAt.contains(' ') || textAfterAt.contains('\n')) {
      _removeOverlay(clearSuggestions: true);
      return;
    }

    // Extract the query after @
    final query = textAfterAt;

    _mentionStartPosition = lastAtIndex;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 180),
      () => _searchUsers(query),
    );
  }

  Future<void> _searchUsers(String query) async {
    final token = ++_activeSearchToken;

    try {
      final users =
          await widget.mentionsRepository.searchUsers(query, limit: 5);

      if (mounted && token == _activeSearchToken) {
        setState(() {
          _suggestions = users;
        });

        if (users.isNotEmpty) {
          _showOverlay();
        } else {
          _removeOverlay(clearSuggestions: true);
        }
      }
    } catch (e) {
      if (mounted && token == _activeSearchToken) {
        setState(() {
          _suggestions = [];
        });
        _removeOverlay();
      }
    }
  }

  void _showOverlay() {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: 16,
        right: 16,
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
            AppAvatar(
              radius: 16,
              imageUrl: user.avatarUrl,
              backgroundColor: AppColors.primary400.withValues(alpha: 0.2),
              fallback: Text(
                user.username[0].toUpperCase(),
                style: AppTypography.custom(
                  color: AppColors.primary400,
                  size: 12,
                  weight: FontWeight.w600,
                ),
              ),
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
    final normalizedUsername = user.username.startsWith('@')
        ? user.username.substring(1)
        : user.username;
    final mentionText = '@$normalizedUsername ';

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

  void _removeOverlay({bool clearSuggestions = false}) {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (!mounted) return;
    if (!clearSuggestions || _suggestions.isEmpty) return;
    setState(() {
      _suggestions = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final focusedBorderColor = widget.showFocusHighlight
        ? AppColors.primary400
        : AppColors.borderSubtle;
    final focusedBorderWidth = widget.showFocusHighlight ? 1.5 : 1.0;

    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        maxLines: widget.maxLines,
        minLines: widget.minLines,
        inputFormatters: widget.maxLength == null
            ? null
            : <TextInputFormatter>[
                LengthLimitingTextInputFormatter(widget.maxLength),
              ],
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
              color: focusedBorderColor,
              width: focusedBorderWidth,
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
