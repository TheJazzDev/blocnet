import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/hunter/presentation/widgets/become_hunter/become_hunter_form.dart';
import 'package:blocnet/features/hunter/presentation/widgets/become_hunter/become_hunter_hero.dart';
import 'package:blocnet/features/hunter/presentation/widgets/become_hunter/become_hunter_status_card.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/users/hunter_application_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Explains what a Hunter does and lets a user apply for the role
/// (`POST /admin-applications`, `targetRole: hunter`). Shows the pending
/// state once an application is on file and a shortcut to Hunter space
/// once the role has been granted.
class BecomeHunterScreen extends StatelessWidget {
  const BecomeHunterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();
    final applicationStore = context.watch<HunterApplicationStore>();

    final Widget body;
    if (auth.hasHunterSpace) {
      body = BecomeHunterStatusCard.alreadyHunter(
        onOpenHunterSpace: () {
          Navigator.of(context).pop();
          auth.switchSpaceWithTransition('hunter');
        },
      );
    } else if (applicationStore.isPending) {
      body = const BecomeHunterStatusCard.pending();
    } else {
      body = const BecomeHunterForm();
    }

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: const CustomAppBar(
        title: 'Become a Hunter',
        backButton: true,
        showSearch: false,
        showFilter: false,
        showSpaceSwitcher: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.xl, AppSpace.lg, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BecomeHunterHero(),
            const SizedBox(height: AppSpace.xl),
            body,
          ],
        ),
      ),
    );
  }
}
