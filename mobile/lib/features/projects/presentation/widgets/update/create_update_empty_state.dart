import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/projects/presentation/widgets/update/composer/composer_notice.dart';
import 'package:flutter/material.dart';

/// Create Update when the account has no gem it can post to: how a gem gets
/// assigned, and the one thing to do now — submit a new gem.
class CreateUpdateEmptyState extends StatelessWidget {
  const CreateUpdateEmptyState({super.key, required this.isHunterRestricted});

  final bool isHunterRestricted;

  @override
  Widget build(BuildContext context) {
    return ComposerNotice(
      icon: Icons.diamond_outlined,
      title: isHunterRestricted
          ? 'No gems assigned to you yet'
          : 'No gem to post to yet',
      message: 'An admin assigns gems to hunters. Submit one you found and '
          'it can be assigned to you once approved.',
      actionLabel: 'Submit a new gem',
      actionIcon: Icons.add_rounded,
      onAction: () => Navigator.of(context).pushNamed(AppRoutes.submitProject),
    );
  }
}
