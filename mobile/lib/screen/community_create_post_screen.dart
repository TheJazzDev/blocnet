import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/community/data/models/community_topic.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/services/auth_store.dart';
import 'package:blocnet/services/community_posts_store.dart';
import 'package:flutter/material.dart';
import 'package:blocnet/app/typography.dart';
import 'package:provider/provider.dart';

class CommunityCreatePostScreen extends StatefulWidget {
  const CommunityCreatePostScreen({super.key});

  @override
  State<CommunityCreatePostScreen> createState() =>
      _CommunityCreatePostScreenState();
}

class _CommunityCreatePostScreenState extends State<CommunityCreatePostScreen> {
  final TextEditingController _contentCtrl = TextEditingController();
  final FocusNode _contentFocus = FocusNode();
  final List<CommunityTopic> _topics = const [
    CommunityTopic.general,
    CommunityTopic.marketTalk,
    CommunityTopic.introductions,
  ];
  CommunityTopic _selectedTopic = CommunityTopic.general;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _contentFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _contentCtrl.dispose();
    _contentFocus.dispose();
    super.dispose();
  }

  Future<void> _submitPost() async {
    final content = _contentCtrl.text.trim();
    if (content.isEmpty) return;

    try {
      final created = await context.read<CommunityPostsStore>().createPost(
            content: content,
            topic: _selectedTopic,
          );

      if (!mounted) return;

      if (created == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create post')),
        );
        return;
      }

      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create post')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();
    final store = context.watch<CommunityPostsStore>();

    final displayName = auth.displayName?.trim().isNotEmpty == true
        ? auth.displayName!.trim()
        : (auth.email ?? 'Blocnet User').split('@').first;
    final avatarUrl = auth.avatarUrl;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: const CustomAppBar(
        title: 'Create Post',
        backButton: true,
        showSearch: false,
        showFilter: false,
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
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.bgElevated,
                            backgroundImage:
                                avatarUrl != null && avatarUrl.isNotEmpty
                                    ? NetworkImage(avatarUrl)
                                    : null,
                            child: avatarUrl == null || avatarUrl.isEmpty
                                ? Text(
                                    displayName.isNotEmpty
                                        ? displayName[0].toUpperCase()
                                        : 'B',
                                    style: AppTypography.custom(
                                      color: AppColors.primary400,
                                      size: 16,
                                      weight: FontWeight.w700,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: AppTypography.custom(
                                    color: AppColors.textPrimary,
                                    size: 14,
                                    weight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  auth.email ?? '@blocnet.user',
                                  style: AppTypography.custom(color: AppColors.textMuted,
                                    size: 12,
                                    weight: FontWeight.w400,),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _contentCtrl,
                        focusNode: _contentFocus,
                        autofocus: true,
                        minLines: 8,
                        maxLines: 12,
                        onTapOutside: (_) =>
                            FocusManager.instance.primaryFocus?.unfocus(),
                        style: AppTypography.custom(color: AppColors.textSecondary,
                          size: 14,
                          weight: FontWeight.w400,
                          height: 1.45,),
                        decoration: InputDecoration(
                          hintText: "What's on your mind?",
                          hintStyle: AppTypography.custom(color: AppColors.textFaint,
                            size: 14,
                            weight: FontWeight.w400,),
                          filled: false,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 2),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'TOPIC',
                        style: AppTypography.custom(
                          color: AppColors.textFaint,
                          size: 10,
                          weight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _topics.map((topic) {
                          final isActive = _selectedTopic == topic;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedTopic = topic),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppColors.primary500
                                        .withValues(alpha: 0.15)
                                    : AppColors.bgSurface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isActive
                                      ? AppColors.primary400
                                          .withValues(alpha: 0.6)
                                      : AppColors.borderSubtle,
                                ),
                              ),
                              child: Text(
                                topic.label,
                                style: AppTypography.custom(
                                  color: isActive
                                      ? AppColors.primary400
                                      : AppColors.textSecondary,
                                  size: 12,
                                  weight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: store.isSubmittingPost ? null : _submitPost,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary500,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        disabledBackgroundColor:
                            AppColors.primary500.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: store.isSubmittingPost
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Post',
                              style: AppTypography.custom(size: 14,
                                color: Colors.black,
                                weight: FontWeight.w700,),
                            ),
                    ),
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
