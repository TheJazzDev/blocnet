import 'dart:io';

import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/badges/presentation/widgets/progress_style.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/features/quests/data/models/quest_models.dart';
import 'package:blocnet/features/quests/presentation/widgets/detail/quest_detail_footer.dart';
import 'package:blocnet/features/quests/presentation/widgets/detail/quest_detail_sections.dart';
import 'package:blocnet/features/quests/presentation/widgets/detail/quest_proof_section.dart';
import 'package:blocnet/services/engagement/quests_store.dart';
import 'package:blocnet/shared/utils/external_url_launcher.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:blocnet/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

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
  static const _maxScreenshotBytes = 8 * 1024 * 1024;

  final _imagePicker = ImagePicker();
  final _noteController = TextEditingController();
  File? _screenshot;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  QuestModel get _quest => widget.quest;
  QuestStatus get _status => widget.userQuest?.status ?? QuestStatus.notStarted;
  bool get _isPending => _status == QuestStatus.pendingVerification;
  bool get _isCompleted => _status == QuestStatus.completed;

  String? get _targetUrl {
    final raw = _quest.targetUrl?.trim();
    if (raw != null && raw.isNotEmpty) return raw;

    final slug = _quest.slug.toLowerCase();
    final title = _quest.title.toLowerCase();
    if (slug.contains('share-on-x') ||
        slug.contains('follow-on-x') ||
        title.contains(' on x')) {
      return 'https://x.com/blocnet_app';
    }
    return null;
  }

  String get _targetButtonLabel {
    final target = _targetUrl?.toLowerCase() ?? '';
    if (target.contains('x.com') || target.contains('twitter.com')) {
      return 'Open X';
    }
    return 'Open link';
  }

  @override
  Widget build(BuildContext context) {
    final url = _targetUrl;
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: const CustomAppBar(
        title: 'Quest',
        backButton: true,
        showSearch: false,
        showFilter: false,
      ),
      body: Consumer<QuestsStore>(
        builder: (context, store, _) {
          return SingleChildScrollView(
            padding: AppSpace.allLg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                QuestDetailHeader(quest: _quest, status: _status),
                AppSpace.gapXl,
                QuestRewardSection(quest: _quest),
                AppSpace.gapLg,
                QuestAboutSection(quest: _quest),
                if (url != null) ...[
                  AppSpace.gapLg,
                  QuestLinkSection(
                    url: url,
                    buttonLabel: _targetButtonLabel,
                    onOpen: () => _launchUrl(url),
                  ),
                ],
                if (_quest.requiresManualVerification && !_isCompleted) ...[
                  AppSpace.gapLg,
                  if (_isPending)
                    const QuestProofPending()
                  else
                    QuestProofForm(
                      screenshot: _screenshot,
                      noteController: _noteController,
                      isSubmitting: store.isSubmitting,
                      onPick: _pickScreenshot,
                      onClearScreenshot: () =>
                          setState(() => _screenshot = null),
                      onSubmit: () => _submitProof(store),
                    ),
                ],
                AppSpace.gapLg,
                _footer(store),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _footer(QuestsStore store) {
    if (_isCompleted) {
      return QuestCompletedCard(completedAt: widget.userQuest?.completedAt);
    }
    if (_isPending) return const SizedBox.shrink();
    if (_quest.isAutoVerified) {
      return AppButton(
        label: 'Verify quest',
        icon: Icons.verified_outlined,
        isLoading: store.isClaiming,
        fullWidth: true,
        onPressed: () => _verifyQuest(store),
      );
    }
    return const QuestManualHint();
  }

  Future<void> _submitProof(QuestsStore store) async {
    final note = _noteController.text.trim();
    final submission = await store.submitQuestProof(
      questSlug: _quest.slug,
      proofText: note.isEmpty ? null : note,
      screenshotFile: _screenshot,
    );
    if (!mounted) return;

    if (submission != null) {
      AppSnackbar.showSuccess(context, 'Proof sent for review');
      _noteController.clear();
      setState(() => _screenshot = null);
      Navigator.pop(context);
    } else {
      AppSnackbar.showError(
        context,
        progressErrorText(
          store.lastError,
          fallback: 'Could not send proof. Try again.',
        ),
      );
    }
  }

  Future<void> _verifyQuest(QuestsStore store) async {
    final result = await store.verifyQuest(_quest.slug);
    if (!mounted) return;

    if (result != null && result.completed) {
      if (result.alreadyCompleted) {
        await showQuestResultDialog(
          context,
          title: 'Already completed',
          message: 'You finished this quest before.',
          isSuccess: true,
        );
      } else {
        final badgeLine = _quest.rewardBadgeId != null
            ? '\n\nYou also unlocked a badge.'
            : '';
        await showQuestResultDialog(
          context,
          title: 'Quest completed',
          message: 'You earned ${result.rewardPoints} BNP.$badgeLine',
          isSuccess: true,
          closeLabel: 'Done',
        );
      }
      if (!mounted) return;
      Navigator.pop(context);
      return;
    }

    if (result != null && !result.eligible) {
      final progressLine = result.targetProgress > 0
          ? '${result.currentProgress}/${result.targetProgress} ${result.metricLabel}'
          : null;
      await showQuestResultDialog(
        context,
        title: 'Not yet',
        message: [
          result.message,
          if (progressLine != null) 'Progress: $progressLine',
          ...result.missingRequirements,
        ].join('\n'),
        isSuccess: false,
      );
      return;
    }

    await showQuestResultDialog(
      context,
      title: 'Could not verify',
      message: progressErrorText(
        store.lastError,
        fallback: 'Try again in a moment.',
      ),
      isSuccess: false,
    );
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
      if (bytes > _maxScreenshotBytes) {
        AppSnackbar.showError(context, 'Screenshot must be 8MB or smaller.');
        return;
      }
      setState(() => _screenshot = file);
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.showError(context, 'Could not open your photos.');
    }
  }

  Future<void> _launchUrl(String url) async {
    final opened = await launchExternalUrlWithAppFallback(url);
    if (!opened && mounted) {
      AppSnackbar.showError(context, 'Could not open link');
    }
  }
}
