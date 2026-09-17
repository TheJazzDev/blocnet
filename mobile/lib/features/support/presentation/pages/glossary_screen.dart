import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
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
          SupportHeader(
            title: 'Words you will see around Blocnet',
            subtitle: '${glossaryTerms.length} terms',
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
      margin: const EdgeInsets.only(bottom: AppSpace.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIconSquare(icon: term.icon),
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
                      style: AppText.body(AppColors.textPrimary,
                          weight: AppText.bold),
                    ),
                    if (expansion != null) ...[
                      const SizedBox(width: AppSpace.sm),
                      Flexible(
                        child: Text(
                          '= $expansion',
                          style: AppText.label(AppColors.primary400,
                              weight: AppText.semibold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpace.sm),
                Text(
                  term.definition,
                  style: AppText.body(AppColors.textSecondary)
                      .copyWith(height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
