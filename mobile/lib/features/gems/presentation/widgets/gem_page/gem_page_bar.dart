import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:flutter/material.dart';

/// Back, the gem's name, and Share.
class GemPageBar extends StatelessWidget {
  const GemPageBar({
    super.key,
    required this.title,
    required this.onBack,
    this.onShare,
  });

  final String title;
  final VoidCallback onBack;

  /// Null until the gem is known.
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            onPressed: onBack,
            icon: Icon(
              Icons.arrow_back_rounded,
              size: AppIcon.lg,
              color: AppColors.textPrimary,
            ),
          ),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  AppText.subtitle(AppColors.textPrimary, weight: AppText.bold),
            ),
          ),
          if (onShare != null)
            IconButton(
              key: const ValueKey('gem-page-share'),
              tooltip: 'Share',
              onPressed: onShare,
              icon: Icon(
                Icons.share_outlined,
                size: AppIcon.md,
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}
