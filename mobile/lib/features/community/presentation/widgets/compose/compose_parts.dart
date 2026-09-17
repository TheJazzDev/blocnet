import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/community/data/models/community_topic.dart';
import 'package:blocnet/shared/widgets/app_avatar.dart';
import 'package:flutter/material.dart';

/// Who is posting: avatar, name and handle.
class ComposeAuthorRow extends StatelessWidget {
  const ComposeAuthorRow({
    super.key,
    required this.name,
    required this.handle,
    required this.avatarUrl,
  });

  final String name;
  final String handle;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppAvatar(
          radius: 20,
          imageUrl: avatarUrl,
          fallback: Text(
            name.isNotEmpty ? name[0].toUpperCase() : 'B',
            style: AppTypography.custom(
              color: AppColors.primary400,
              size: AppText.subtitleSize,
              weight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: AppSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.custom(
                  color: AppColors.textPrimary,
                  size: AppText.bodySize,
                  weight: FontWeight.w700,
                ),
              ),
              if (handle.isNotEmpty)
                Text(
                  handle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.custom(
                    color: AppColors.textMuted,
                    size: AppText.labelSize,
                    weight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The topic choice as a row of outlined pills; the chosen one is tinted.
class ComposeTopicPicker extends StatelessWidget {
  const ComposeTopicPicker({
    super.key,
    required this.topics,
    required this.selected,
    required this.onSelected,
  });

  final List<CommunityTopic> topics;
  final CommunityTopic selected;
  final ValueChanged<CommunityTopic> onSelected;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.primary400;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TOPIC',
          style: AppTypography.custom(
            color: AppColors.textFaint,
            size: AppText.captionSize,
            weight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        Wrap(
          spacing: AppSpace.sm,
          runSpacing: AppSpace.sm,
          children: [
            for (final topic in topics)
              Semantics(
                selected: topic == selected,
                button: true,
                child: GestureDetector(
                  onTap: () => onSelected(topic),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 36),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.lg,
                      vertical: AppSpace.sm,
                    ),
                    decoration: BoxDecoration(
                      color: topic == selected
                          ? accent.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: AppRadius.full,
                      border: Border.all(
                        color: topic == selected
                            ? accent.withValues(alpha: 0.35)
                            : AppColors.borderSubtle,
                      ),
                    ),
                    child: Text(
                      topic.label,
                      style: AppTypography.custom(
                        color: topic == selected
                            ? accent
                            : AppColors.textSecondary,
                        size: AppText.labelSize,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// `1,234 / 5,000` under the field; amber near the limit.
class ComposeCharCount extends StatelessWidget {
  const ComposeCharCount({
    super.key,
    required this.controller,
    required this.max,
  });

  final TextEditingController controller;
  final int max;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final used = value.text.length;
        final near = used > max * 0.9;
        return Align(
          alignment: Alignment.centerRight,
          child: Text(
            '$used / $max',
            style: AppTypography.custom(
              color: near ? AppColors.warning500 : AppColors.textFaint,
              size: AppText.captionSize,
              weight: FontWeight.w500,
            ),
          ),
        );
      },
    );
  }
}
