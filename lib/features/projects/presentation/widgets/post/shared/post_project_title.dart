import 'package:flutter/material.dart';
import 'package:blocknet/app/theme.dart';
import 'package:blocknet/shared/styles/app_text_styles.dart';

class PostProjectTitle extends StatelessWidget {
  const PostProjectTitle({
    required this.projectTitle,
    this.margin = true,
    this.applyOverflow = false,
    super.key,
  });

  final String projectTitle;
  final bool margin;
  final bool applyOverflow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      margin: margin
          ? const EdgeInsets.only(top: 8, left: 16, bottom: 4)
          : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: AppColors.darkGrey100,
        borderRadius: BorderRadius.all(Radius.circular(40)),
      ),
      child: _TitleContent(
        projectTitle: projectTitle,
        applyOverflow: applyOverflow,
      ),
    );
  }
}

class _TitleContent extends StatelessWidget {
  const _TitleContent({
    required this.projectTitle,
    required this.applyOverflow,
  });

  final String projectTitle;
  final bool applyOverflow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.darkGrey400,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.style,
            size: 24,
            color: AppColors.darkGrey400,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: StyledPostProjectTitle(
              projectTitle,
              applyOverflow: applyOverflow,
            ),
          ),
        ],
      ),
    );
  }
}
