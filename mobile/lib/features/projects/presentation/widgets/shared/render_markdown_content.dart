import 'package:blocnet/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class RenderMarkdownContent extends StatelessWidget {
  const RenderMarkdownContent({required this.content, super.key});

  final String content;

  String cleanContent() {
    return content.replaceAll('\r\n', '\n').replaceAll('\t', '    ').trim();
  }

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: cleanContent(),
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
        p: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.textMuted,
          height: 1.8,
          fontFamily: 'Geist',
        ),
        h1: Theme.of(context).textTheme.headlineLarge?.copyWith(
          color: AppColors.textPrimary,
          height: 2.0,
          fontFamily: 'Geist',
          fontWeight: FontWeight.w700,
        ),
        h2: Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: AppColors.textPrimary,
          height: 2.2,
          fontFamily: 'Geist',
          fontWeight: FontWeight.w700,
        ),
        h3: Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: AppColors.textSecondary,
          height: 1.6,
          fontFamily: 'Geist',
          fontWeight: FontWeight.w600,
        ),
        h4: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: AppColors.textSecondary,
          height: 1.5,
          fontFamily: 'Geist',
          fontWeight: FontWeight.w600,
        ),
        h5: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: AppColors.textSecondary,
          height: 1.4,
          fontFamily: 'Geist',
        ),
        h6: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: AppColors.textMuted,
          height: 1.3,
          fontFamily: 'Geist',
        ),
        blockquoteDecoration: BoxDecoration(
          color: AppColors.bgElevated,
          border: Border(
            left: BorderSide(color: AppColors.teal500, width: 3),
          ),
        ),
        code: TextStyle(
          color: AppColors.teal400,
          backgroundColor: AppColors.bgElevated,
          fontFamily: 'monospace',
          fontSize: 12,
        ),
        codeblockDecoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderSubtle),
        ),
      ),
      onTapLink: (text, href, title) async {
        if (href != null) {
          final uri = Uri.parse(href);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            debugPrint('Could not launch $href');
          }
        }
      },
    );
  }
}
