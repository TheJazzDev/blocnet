import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/community/data/models/community_topic.dart';
import 'package:blocnet/features/community/presentation/widgets/compose/compose_parts.dart';
import 'package:blocnet/features/mentions/data/repositories/mentions_repository.dart';
import 'package:blocnet/features/mentions/presentation/widgets/mention_text_field.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/services/api/api_client.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/community/community_posts_store.dart';
import 'package:blocnet/shared/widgets/app_button.dart';
import 'package:blocnet/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Write a community post and pick its topic. Pops with the topic on success
/// so the feed can switch to it.
class CommunityCreatePostScreen extends StatefulWidget {
  const CommunityCreatePostScreen({super.key});

  @override
  State<CommunityCreatePostScreen> createState() =>
      _CommunityCreatePostScreenState();
}

class _CommunityCreatePostScreenState extends State<CommunityCreatePostScreen> {
  /// The server's limit for a community post.
  static const int _maxLength = 5000;
  static const List<CommunityTopic> _topics = [
    CommunityTopic.general,
    CommunityTopic.marketTalk,
  ];

  final TextEditingController _contentCtrl = MentionHighlightTextController();
  final FocusNode _contentFocus = FocusNode();
  final MentionsRepository _mentionsRepository =
      MentionsRepository(ApiClient());
  CommunityTopic _topic = CommunityTopic.general;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _contentFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _contentCtrl.dispose();
    _contentFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final content = _contentCtrl.text.trim();
    if (content.isEmpty) return;
    final store = context.read<CommunityPostsStore>();
    try {
      final created = await store.createPost(content: content, topic: _topic);
      if (!mounted) return;
      if (created == null) {
        AppSnackbar.showError(context, 'Could not publish post');
        return;
      }
      Navigator.of(context).pop(_topic);
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.showError(
        context,
        store.lastError ?? 'Could not publish post',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();
    final isSubmitting = context.watch<CommunityPostsStore>().isSubmittingPost;
    final name = (auth.displayName?.trim().isNotEmpty ?? false)
        ? auth.displayName!.trim()
        : (auth.email ?? 'Blocnet member').split('@').first;
    final raw = auth.username?.trim().replaceAll('@', '') ?? '';

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: const CustomAppBar(
        title: 'New post',
        showSearch: false,
        showFilter: false,
        showNotificationBell: false,
        showSpaceSwitcher: false,
      ),
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.translucent,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpace.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ComposeAuthorRow(
                        name: name,
                        handle: raw.isEmpty ? '' : '@$raw',
                        avatarUrl: auth.avatarUrl,
                      ),
                      const SizedBox(height: AppSpace.lg),
                      MentionTextField(
                        controller: _contentCtrl,
                        focusNode: _contentFocus,
                        mentionsRepository: _mentionsRepository,
                        hintText: 'What’s happening?',
                        minLines: 6,
                        maxLines: 12,
                        maxLength: _maxLength,
                        showFocusHighlight: false,
                      ),
                      const SizedBox(height: AppSpace.xs),
                      ComposeCharCount(
                        controller: _contentCtrl,
                        max: _maxLength,
                      ),
                      const SizedBox(height: AppSpace.md),
                      ComposeTopicPicker(
                        topics: _topics,
                        selected: _topic,
                        onSelected: (topic) => setState(() => _topic = topic),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.lg,
                  AppSpace.sm,
                  AppSpace.lg,
                  AppSpace.md,
                ),
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _contentCtrl,
                  builder: (context, value, _) => AppButton(
                    label: 'Post',
                    fullWidth: true,
                    isLoading: isSubmitting,
                    onPressed: value.text.trim().isEmpty || isSubmitting
                        ? null
                        : _submit,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
