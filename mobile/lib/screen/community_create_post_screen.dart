import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/services/auth_store.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class CommunityCreatePostScreen extends StatefulWidget {
  const CommunityCreatePostScreen({super.key});

  @override
  State<CommunityCreatePostScreen> createState() =>
      _CommunityCreatePostScreenState();
}

class _CommunityCreatePostScreenState extends State<CommunityCreatePostScreen> {
  final TextEditingController _contentCtrl = TextEditingController();
  final List<String> _topics = const [
    'Market Talk',
    'Introductions',
    'DeFi',
    'Alpha',
  ];
  String _selectedTopic = 'Market Talk';

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  void _submitPost() {
    final content = _contentCtrl.text.trim();
    if (content.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Post composer UI is ready. API hookup next.')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();
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
      body: SafeArea(
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
                                  style: GoogleFonts.inter(
                                    color: AppColors.primary400,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
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
                                style: GoogleFonts.inter(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                auth.email ?? '@blocnet.user',
                                style: GoogleFonts.inter(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _contentCtrl,
                      minLines: 8,
                      maxLines: 12,
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.45,
                      ),
                      decoration: InputDecoration(
                        hintText: "What's on your mind?",
                        hintStyle: GoogleFonts.inter(
                          color: AppColors.textFaint,
                          fontSize: 14,
                        ),
                        filled: false,
                        contentPadding: const EdgeInsets.symmetric(vertical: 2),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'TOPIC',
                      style: GoogleFonts.inter(
                        color: AppColors.textFaint,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
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
                                  ? AppColors.primary500.withValues(alpha: 0.15)
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
                              topic,
                              style: GoogleFonts.inter(
                                color: isActive
                                    ? AppColors.primary400
                                    : AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.bgSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Row(
                        children: const [
                          _ComposerAction(
                              icon: Icons.photo_outlined, label: 'Photo'),
                          SizedBox(width: 18),
                          _ComposerAction(
                              icon: Icons.poll_outlined, label: 'Poll'),
                          SizedBox(width: 18),
                          _ComposerAction(
                              icon: Icons.link_rounded, label: 'Link'),
                        ],
                      ),
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
                    onPressed: _submitPost,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary500,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Post',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComposerAction extends StatelessWidget {
  const _ComposerAction({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            color: AppColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
