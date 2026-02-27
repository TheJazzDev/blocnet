import 'dart:io';

import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/badges/presentation/widgets/badge_icon.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/features/quests/data/models/quest_models.dart';
import 'package:blocnet/services/quests_store.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class QuestDetailPage extends StatefulWidget {
  const QuestDetailPage({
    super.key,
    required this.quest,
    this.userQuest,
  });

  final QuestModel quest;
  final UserQuestModel? userQuest;

  @override
  State<QuestDetailPage> createState() => _QuestDetailPageState();
}

class _QuestDetailPageState extends State<QuestDetailPage> {
  final _imagePicker = ImagePicker();
  final _proofTextController = TextEditingController();
  File? _selectedScreenshot;

  @override
  void dispose() {
    _proofTextController.dispose();
    super.dispose();
  }

  QuestStatus get _status => widget.userQuest?.status ?? QuestStatus.notStarted;
  bool get _isPending => _status == QuestStatus.pendingVerification;
  bool get _isCompleted => _status == QuestStatus.completed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: const CustomAppBar(
        title: 'Quest Details',
        backButton: true,
        showSearch: false,
        showFilter: false,
      ),
      body: Consumer<QuestsStore>(
        builder: (context, store, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildQuestHeader(),
                const SizedBox(height: 24),
                _buildQuestInfo(),
                const SizedBox(height: 24),
                _buildRewardsSection(),
                const SizedBox(height: 24),
                if (widget.quest.targetUrl != null) ...[
                  _buildTargetSection(),
                  const SizedBox(height: 24),
                ],
                if (widget.quest.requiresManualVerification &&
                    !_isCompleted) ...[
                  _buildProofSubmissionSection(store),
                  const SizedBox(height: 24),
                ],
                _buildActionSection(store),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuestHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(_status.color).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.quest.type.iconData,
              size: 48,
              color: Color(_status.color),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.quest.title,
            textAlign: TextAlign.center,
            style: AppTypography.custom(
              color: AppColors.textPrimary,
              size: 20,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              BadgeCategoryChip(category: widget.quest.category),
              const SizedBox(width: 8),
              _QuestTypeChip(type: widget.quest.type),
            ],
          ),
          if (_status != QuestStatus.notStarted) ...[
            const SizedBox(height: 12),
            _QuestStatusChip(status: _status),
          ],
        ],
      ),
    );
  }

  Widget _buildQuestInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description',
            style: AppTypography.custom(
              color: AppColors.textPrimary,
              size: 15,
              weight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.quest.description,
            style: AppTypography.custom(
              color: AppColors.textMuted,
              size: 13,
              weight: FontWeight.w400,
            ),
          ),
          if (widget.quest.requiredProof != null) ...[
            const SizedBox(height: 16),
            Text(
              'Required Proof',
              style: AppTypography.custom(
                color: AppColors.textPrimary,
                size: 15,
                weight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.quest.requiredProof!,
              style: AppTypography.custom(
                color: AppColors.textSecondary,
                size: 13,
                weight: FontWeight.w400,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                widget.quest.isAutoVerified ? Icons.verified : Icons.fact_check,
                size: 16,
                color: AppColors.textFaint,
              ),
              const SizedBox(width: 8),
              Text(
                widget.quest.isAutoVerified
                    ? 'Auto-verified quest'
                    : 'Manual verification required',
                style: AppTypography.custom(
                  color: AppColors.textFaint,
                  size: 11,
                  weight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRewardsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rewards',
            style: AppTypography.custom(
              color: AppColors.textPrimary,
              size: 15,
              weight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.stars,
                size: 32,
                color: AppColors.warning500,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.quest.rewardPoints} BNP',
                    style: AppTypography.custom(
                      color: AppColors.warning500,
                      size: 16,
                      weight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Boost your mining earnings',
                    style: AppTypography.custom(
                      color: AppColors.textFaint,
                      size: 11,
                      weight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (widget.quest.rewardBadgeId != null) ...[
            const SizedBox(height: 12),
            Divider(color: AppColors.borderSubtle),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.emoji_events,
                  size: 32,
                  color: AppColors.secondary500,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Exclusive Badge',
                      style: AppTypography.custom(
                        color: AppColors.secondary500,
                        size: 16,
                        weight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Unlock a special achievement badge',
                      style: AppTypography.custom(
                        color: AppColors.textFaint,
                        size: 11,
                        weight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTargetSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How to Complete',
            style: AppTypography.custom(
              color: AppColors.textPrimary,
              size: 15,
              weight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgBase,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.borderSubtle,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.link,
                  color: AppColors.primary500,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.quest.targetUrl!,
                    style: AppTypography.custom(
                      color: AppColors.primary500,
                      size: 12,
                      weight: FontWeight.w400,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _launchUrl(widget.quest.targetUrl!),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open Link'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary500,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProofSubmissionSection(QuestsStore store) {
    if (_isPending) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.warning500.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.warning500.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.pending,
              size: 48,
              color: AppColors.warning500,
            ),
            const SizedBox(height: 12),
            Text(
              'Proof Submitted',
              style: AppTypography.custom(
                color: AppColors.warning500,
                size: 16,
                weight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your submission is pending admin verification. You will be notified once reviewed.',
              textAlign: TextAlign.center,
              style: AppTypography.custom(
                color: AppColors.textSecondary,
                size: 12,
                weight: FontWeight.w400,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Submit Proof',
            style: AppTypography.custom(
              color: AppColors.textPrimary,
              size: 15,
              weight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Provide proof that you completed this quest. Admin will review and verify your submission.',
            style: AppTypography.custom(
              color: AppColors.textSecondary,
              size: 12,
              weight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: store.isSubmitting ? null : _pickScreenshot,
              icon: const Icon(Icons.image_outlined),
              label: Text(
                _selectedScreenshot == null
                    ? 'Upload Screenshot'
                    : 'Change Screenshot',
              ),
            ),
          ),
          if (_selectedScreenshot != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  Image.file(
                    _selectedScreenshot!,
                    height: 170,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.45),
                      ),
                      onPressed: () =>
                          setState(() => _selectedScreenshot = null),
                      icon:
                          const Icon(Icons.close_rounded, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _proofTextController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Additional Details (optional)',
              hintText: 'Any additional information',
              prefixIcon: Icon(Icons.description),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_selectedScreenshot == null) || store.isSubmitting
                  ? null
                  : () => _submitProof(store),
              icon: store.isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload),
              label: Text(
                store.isSubmitting ? 'Submitting...' : 'Submit Proof',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary500,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSection(QuestsStore store) {
    if (_isCompleted) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.successColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.successColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.check_circle,
              size: 48,
              color: AppColors.successColor,
            ),
            const SizedBox(height: 12),
            Text(
              'Quest Completed!',
              style: AppTypography.custom(
                color: AppColors.successColor,
                size: 16,
                weight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You have successfully completed this quest and received your rewards.',
              textAlign: TextAlign.center,
              style: AppTypography.custom(
                color: AppColors.textSecondary,
                size: 12,
                weight: FontWeight.w400,
              ),
            ),
            if (widget.userQuest?.completedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Completed ${_formatDate(widget.userQuest!.completedAt!)}',
                style: AppTypography.custom(
                  color: AppColors.textFaint,
                  size: 11,
                  weight: FontWeight.w400,
                ),
              ),
            ],
          ],
        ),
      );
    }

    if (_isPending) {
      return const SizedBox.shrink();
    }

    if (widget.quest.isAutoVerified) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: store.isClaiming ? null : () => _verifyQuest(store),
          icon: store.isClaiming
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.verified_outlined),
          label: Text(store.isClaiming ? 'Verifying...' : 'Verify Quest'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: AppColors.primary500,
            foregroundColor: Colors.white,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Text(
        'Submit your proof above to send this quest for admin review.',
        style: AppTypography.custom(
          color: AppColors.textSecondary,
          size: 12,
          weight: FontWeight.w400,
        ),
      ),
    );
  }

  Future<void> _submitProof(QuestsStore store) async {
    final submission = await store.submitQuestProof(
      questSlug: widget.quest.slug,
      proofText: _proofTextController.text.trim().isEmpty
          ? null
          : _proofTextController.text.trim(),
      screenshotFile: _selectedScreenshot,
    );

    if (mounted) {
      if (submission != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Proof submitted for verification!'),
            backgroundColor: AppColors.successColor,
          ),
        );
        _proofTextController.clear();
        setState(() => _selectedScreenshot = null);
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(store.lastError ?? 'Failed to submit proof'),
            backgroundColor: AppColors.error500,
          ),
        );
      }
    }
  }

  Future<void> _verifyQuest(QuestsStore store) async {
    final result = await store.verifyQuest(widget.quest.slug);
    if (mounted) {
      if (result != null && result.completed) {
        if (result.alreadyCompleted) {
          await _showVerificationResultModal(
            title: 'Already Completed',
            message: 'This quest has already been completed.',
            isSuccess: true,
          );
          if (!mounted) return;
          Navigator.pop(context);
          return;
        }
        final suffix = widget.quest.rewardBadgeId != null
            ? '\n\nYou also unlocked a badge.'
            : '';
        await _showVerificationResultModal(
          title: 'Quest Completed',
          message: 'You earned ${result.rewardPoints} BNP.$suffix',
          isSuccess: true,
          closeLabel: 'Done',
        );
        if (!mounted) return;
        Navigator.pop(context);
      } else if (result != null && !result.eligible) {
        final progressLine = result.targetProgress > 0
            ? '${result.currentProgress}/${result.targetProgress} ${result.metricLabel}'
            : null;
        final details = <String>[
          result.message,
          if (progressLine != null) 'Progress: $progressLine',
          ...result.missingRequirements,
        ].join('\n');
        await _showVerificationResultModal(
          title: 'Not Eligible Yet',
          message: details,
          isSuccess: false,
        );
      } else {
        await _showVerificationResultModal(
          title: 'Verification Failed',
          message: store.lastError ?? 'Failed to verify quest',
          isSuccess: false,
        );
      }
    }
  }

  Future<void> _pickScreenshot() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1800,
      );
      if (image == null) return;

      final file = File(image.path);
      final bytes = await file.length();
      if (!mounted) return;
      if (bytes > 8 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Screenshot must be 8MB or smaller.'),
            backgroundColor: AppColors.error500,
          ),
        );
        return;
      }

      setState(() => _selectedScreenshot = file);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not pick image right now.'),
          backgroundColor: AppColors.error500,
        ),
      );
    }
  }

  Future<void> _showVerificationResultModal({
    required String title,
    required String message,
    required bool isSuccess,
    String closeLabel = 'Close',
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgSurface,
        title: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.info_outline,
              color: isSuccess ? AppColors.successColor : AppColors.warning500,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: AppTypography.custom(
                  color: AppColors.textPrimary,
                  size: 16,
                  weight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            message,
            style: AppTypography.custom(
              color: AppColors.textSecondary,
              size: 13,
              weight: FontWeight.w400,
              height: 1.5,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary500,
            ),
            child: Text(
              closeLabel,
              style: AppTypography.custom(
                color: AppColors.primary500,
                size: 13,
                weight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not open link'),
            backgroundColor: AppColors.error500,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'today';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
    return '${(diff.inDays / 30).floor()} months ago';
  }
}

class _QuestTypeChip extends StatelessWidget {
  const _QuestTypeChip({
    required this.type,
  });

  final QuestType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.bgBase,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            type.iconData,
            size: 14,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: 4),
          Text(
            type.displayName,
            style: AppTypography.custom(
              color: AppColors.textMuted,
              size: 12,
              weight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestStatusChip extends StatelessWidget {
  const _QuestStatusChip({
    required this.status,
  });

  final QuestStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Color(status.color).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Color(status.color).withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(status),
            size: 16,
            color: Color(status.color),
          ),
          const SizedBox(width: 6),
          Text(
            status.displayName,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(status.color),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(QuestStatus status) {
    switch (status) {
      case QuestStatus.notStarted:
        return Icons.radio_button_unchecked;
      case QuestStatus.inProgress:
        return Icons.pending;
      case QuestStatus.pendingVerification:
        return Icons.hourglass_empty;
      case QuestStatus.completed:
        return Icons.check_circle;
    }
  }
}
