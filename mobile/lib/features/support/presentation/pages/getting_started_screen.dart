import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/features/support/data/getting_started_content.dart';
import 'package:blocnet/features/support/presentation/widgets/support_widgets.dart';
import 'package:flutter/material.dart';

/// Static Getting Started guide: the first things to do on Blocnet, in
/// order, with shortcuts into the app where a step has one.
class GettingStartedScreen extends StatelessWidget {
  const GettingStartedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: const CustomAppBar(
        title: 'Getting Started',
        backButton: true,
        showSearch: false,
        showFilter: false,
        showSpaceSwitcher: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.lg),
        children: [
          const SupportHeader(
            title: 'Your first week on Blocnet',
            subtitle: 'Seven steps, in the order that makes the app click. You '
                'can do them all in one sitting.',
          ),
          const SizedBox(height: AppSpace.lg),
          for (var i = 0; i < gettingStartedSteps.length; i++)
            SupportStepCard(
              number: i + 1,
              icon: gettingStartedSteps[i].icon,
              title: gettingStartedSteps[i].title,
              body: gettingStartedSteps[i].body,
              actionLabel: gettingStartedSteps[i].actionLabel,
              onAction: gettingStartedSteps[i].route == null
                  ? null
                  : () => Navigator.of(context)
                      .pushNamed(gettingStartedSteps[i].route!),
            ),
          const SizedBox(height: AppSpace.xl),
        ],
      ),
    );
  }
}
