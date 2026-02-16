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
          color: AppColors.darkGrey500,
          height: 1.8,
        ),
        h1: Theme.of(context).textTheme.headlineLarge?.copyWith(
          color: AppColors.darkGrey600,
          height: 2.0,
        ),
        h2: Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: AppColors.darkGrey600,
          height: 2.2,
        ),
        h3: Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: AppColors.darkGrey500,
          height: 1.6,
        ),
        h4: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: AppColors.darkGrey500,
          height: 1.5,
        ),
        h5: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: AppColors.darkGrey500,
          height: 1.4,
        ),
        h6: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: AppColors.darkGrey500,
          height: 1.3,
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
