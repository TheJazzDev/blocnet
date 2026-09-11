import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/features/support/data/glossary_content.dart';
import 'package:blocnet/features/support/presentation/widgets/support_widgets.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';

/// Static glossary of Blocnet vocabulary, reachable from Help & Support.
class GlossaryScreen extends StatelessWidget {
  const GlossaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: const CustomAppBar(
        title: 'Glossary',
        backButton: true,
        showSearch: false,
        showFilter: false,
        showSpaceSwitcher: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.lg),
        children: [
          const SupportHeader(
            title: 'Words you will see around Blocnet',
            subtitle:
                'Users find Gems, Hunters post Updates, and BNP becomes BNT '
                'at launch. Here is what each term means.',
          ),
          const SizedBox(height: AppSpace.lg),
          for (final term in glossaryTerms) _GlossaryCard(term: term),
          const SizedBox(height: AppSpace.xl),
        ],
      ),
    );
  }
}

class _GlossaryCard extends StatelessWidget {
  const _GlossaryCard({required this.term});

  final GlossaryTerm term;

  @override
  Widget build(BuildContext context) {
    final expansion = term.expansion;

    return AppSurface(
      margin: const EdgeInsets.only(bottom: AppSpace.md),
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primary500.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.mdValue),
            ),
            child:
                Icon(term.icon, size: AppIcon.sm, color: AppColors.primary400),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      term.term,
                      style: AppTypography.custom(
                        color: AppColors.textPrimary,
                        size: AppText.bodySize,
                        weight: FontWeight.w700,
                      ),
                    ),
                    if (expansion != null) ...[
                      const SizedBox(width: AppSpace.sm),
                      Flexible(
                        child: Text(
                          '= $expansion',
                          style: AppTypography.custom(
                            color: AppColors.primary400,
                            size: AppText.captionSize,
                            weight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpace.sm),
                Text(
                  term.definition,
                  style: AppTypography.custom(
                    color: AppColors.textSecondary,
                    size: AppText.bodySize,
                    weight: FontWeight.w400,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
