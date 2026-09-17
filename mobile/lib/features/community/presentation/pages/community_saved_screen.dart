import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/community/presentation/widgets/saved/community_saved_body.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/services/community/community_posts_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The community posts the member saved, newest save first.
class CommunitySavedScreen extends StatefulWidget {
  const CommunitySavedScreen({super.key});

  @override
  State<CommunitySavedScreen> createState() => _CommunitySavedScreenState();
}

class _CommunitySavedScreenState extends State<CommunitySavedScreen> {
  @override
  void initState() {
    super.initState();
    // Always reload on open: a save made on another device should show.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CommunityPostsStore>().loadSavedPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: CustomAppBar(
        title: 'Saved',
        showSearch: false,
        showFilter: false,
        showNotificationBell: false,
        showSpaceSwitcher: false,
      ),
      body: CommunitySavedBody(),
    );
  }
}
