import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';

class MentionText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextStyle? mentionStyle;
  final int? maxLines;
  final TextOverflow? overflow;
  final Function(String username)? onMentionTap;

  const MentionText({
    super.key,
    required this.text,
    this.style,
    this.mentionStyle,
    this.maxLines,
    this.overflow,
    this.onMentionTap,
  });

  @override
  Widget build(BuildContext context) {
    final defaultStyle = style ??
        AppTypography.custom(
          color: AppColors.textSecondary,
          size: 13,
          weight: FontWeight.w400,
        );

    final defaultMentionStyle = mentionStyle ??
        AppTypography.custom(
          color: AppColors.primary400,
          size: 13,
          weight: FontWeight.w600,
        );

    return Text.rich(
      _buildTextSpan(text, defaultStyle, defaultMentionStyle),
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  TextSpan _buildTextSpan(
    String text,
    TextStyle defaultStyle,
    TextStyle mentionStyle,
  ) {
    final mentionRegex = RegExp(r'@([a-zA-Z0-9._-]+)');
    final matches = mentionRegex.allMatches(text);

    if (matches.isEmpty) {
      return TextSpan(text: text, style: defaultStyle);
    }

    final spans = <TextSpan>[];
    int currentPosition = 0;

    for (final match in matches) {
      // Add text before mention
      if (match.start > currentPosition) {
        spans.add(
          TextSpan(
            text: text.substring(currentPosition, match.start),
            style: defaultStyle,
          ),
        );
      }

      // Add mention
      final username = match.group(1)!;
      spans.add(
        TextSpan(
          text: '@$username',
          style: mentionStyle,
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              if (onMentionTap != null) {
                onMentionTap!(username);
              }
            },
        ),
      );

      currentPosition = match.end;
    }

    // Add remaining text
    if (currentPosition < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(currentPosition),
          style: defaultStyle,
        ),
      );
    }

    return TextSpan(children: spans);
  }
}
