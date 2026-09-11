import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/features/support/data/faq_content.dart';
import 'package:blocnet/features/support/presentation/widgets/support_widgets.dart';
import 'package:flutter/material.dart';

/// Static FAQ: what Gems, Hunters, Updates, Alpha Radar, Edge briefs,
/// mining, quests, badges, levels, spaces, tips and BNP / BNT are.
class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: const CustomAppBar(
        title: 'FAQs',
        backButton: true,
        showSearch: false,
        showFilter: false,
        showSpaceSwitcher: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.lg),
        children: [
          const SupportHeader(
            title: 'Frequently asked questions',
            subtitle:
                'Short answers to the things people ask most. Tap a question '
                'to expand it.',
          ),
          const SizedBox(height: AppSpace.lg),
          for (final entry in faqEntries)
            SupportFaqTile(
              icon: entry.icon,
              question: entry.question,
              answer: entry.answer,
            ),
          const SizedBox(height: AppSpace.xl),
        ],
      ),
    );
  }
}
