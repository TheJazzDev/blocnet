import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/main/presentation/navigation/main_tab_navigator.dart';
import 'package:blocnet/features/profile/domain/activity_target.dart';
import 'package:blocnet/features/profile/presentation/pages/public_profile_screen.dart';
import 'package:blocnet/features/projects/data/models/admin_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/detail_dialogs.dart';
import 'package:flutter/material.dart';

/// Opens what an Activity row refers to.
void openActivityTarget(BuildContext context, ActivityTarget target) {
  final id = target.id;
  switch (target.kind) {
    case ActivityTargetKind.update:
      if (id != null) showUpdateDetailsDialog(context, id);
    case ActivityTargetKind.gem:
      if (id != null) showGemDetailsDialog(context, id);
    case ActivityTargetKind.communityPost:
      if (id != null) {
        Navigator.of(context).pushNamed(
          AppRoutes.communityDiscussion,
          arguments: id,
        );
      }
    case ActivityTargetKind.person:
      if (id != null) {
        // The public profile fills in name and avatar from its own fetch.
        PublicProfileScreen.showSheet(
          context,
          Admin(id: id, name: '', username: '', imageUrl: '', followers: 0),
        );
      }
    case ActivityTargetKind.mine:
      MainTabNavigator.openRoute(context, AppRoutes.mining);
    case ActivityTargetKind.referrals:
      Navigator.of(context).pushNamed(AppRoutes.miningEarnFaster);
  }
}
