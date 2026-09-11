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
/// (`POST /admin-applications`, `targetRole: hunter`). The body follows
/// the newest application's server state: pending, approved (until the
/// role lands), not approved (form shown again), or already a hunter.
class BecomeHunterScreen extends StatefulWidget {
  const BecomeHunterScreen({super.key});

  @override
  State<BecomeHunterScreen> createState() => _BecomeHunterScreenState();
}

class _BecomeHunterScreenState extends State<BecomeHunterScreen> {
  @override
  void initState() {
    super.initState();
    // A decision may have landed since the app booted.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<HunterApplicationStore>().refreshFromServer();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();
    final applicationStore = context.watch<HunterApplicationStore>();

    final List<Widget> body;
    if (auth.hasHunterSpace) {
      body = [
        BecomeHunterStatusCard.alreadyHunter(
          onOpenHunterSpace: () {
            Navigator.of(context).pop();
            auth.switchSpaceWithTransition('hunter');
          },
        ),
      ];
    } else if (applicationStore.isPending) {
      body = const [BecomeHunterStatusCard.pending()];
    } else if (applicationStore.isApproved) {
      body = const [BecomeHunterStatusCard.approved()];
    } else if (applicationStore.isRejected) {
      body = const [
        BecomeHunterStatusCard.rejected(),
        AppSpace.gapXl,
        BecomeHunterForm(),
      ];
    } else {
      body = const [BecomeHunterForm()];
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
        padding: const EdgeInsets.fromLTRB(
          AppSpace.lg,
          AppSpace.xl,
          AppSpace.lg,
          AppSpace.xxl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BecomeHunterHero(),
            AppSpace.gapXl,
            ...body,
          ],
        ),
      ),
    );
  }
}
