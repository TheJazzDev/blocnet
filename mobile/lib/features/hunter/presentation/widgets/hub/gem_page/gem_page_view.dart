import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/hunter/data/models/hunter_board_model.dart';
import 'package:blocnet/features/hunter/data/models/hunter_gem_detail_model.dart';
import 'package:blocnet/features/hunter/domain/hub_format.dart';
import 'package:blocnet/features/hunter/domain/hub_layout.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/board/gem_attention_parts.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/gem_page/gem_notice_cards.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/gem_page/gem_timeline.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/gem_header_line.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_styles.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';

/// The gem page body (design state 6): header, the wait and the reports the
/// hunter came to answer, *Post update* beside *Hand over*, then their
/// updates newest first.
class GemPageView extends StatelessWidget {
  const GemPageView({
    super.key,
    required this.gem,
    required this.detail,
    required this.loading,
    required this.error,
    required this.now,
    required this.onPost,
    required this.onHandover,
    required this.onEdit,
    required this.onRetry,
    required this.onRefresh,
  });

  /// The freshest copy of the gem: the page's own payload once loaded,
  /// otherwise the board row it was opened from.
  final HunterBoardGem gem;
  final HunterGemDetail? detail;
  final bool loading;
  final String? error;
  final DateTime now;
  final VoidCallback onPost;

  /// Offers a handover, or shows the pending one ([HunterGemDetail.pendingHandover]).
  final VoidCallback onHandover;
  final ValueChanged<HunterGemEvent> onEdit;
  final VoidCallback onRetry;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final isQuiet = gem.chip == GemChip.quiet;
    final gapDays = isQuiet ? (detail?.gapDays ?? gem.daysQuiet) : null;

    return RefreshIndicator(
      color: HubTone.accent,
      backgroundColor: AppColors.bgSurface,
      onRefresh: onRefresh,
      child: ListView(
        key: const ValueKey('gem-page-scroll'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(HubInsets.gutter),
        children: [
          GemHeaderLine(
            key: const ValueKey('gem-header'),
            gem: gem,
            large: true,
          ),
          if (gem.membersWaiting > 0) ...[
            AppSpace.gapLg,
            GemWaitCard(
              key: const ValueKey('gem-wait'),
              waiting: gem.membersWaiting,
            ),
          ],
          if (gem.openReports > 0) ...[
            AppSpace.gapSm,
            GemReportCard(
              key: const ValueKey('gem-report'),
              reports: gem.openReports,
            ),
          ],
          AppSpace.gapLg,
          _actions(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpace.lg),
            child: Divider(height: 1, color: AppColors.borderSubtle),
          ),
          _timeline(gapDays),
        ],
      ),
    );
  }

  /// `.gact`: *Post update* (filled) and *Hand over* (warn), equal width.
  Widget _actions() {
    final pending = detail?.pendingHandover != null;
    return Row(
      key: const ValueKey('gem-actions'),
      children: [
        Expanded(
          child: AppButton(
            key: const ValueKey('gem-post'),
            label: gem.neverUpdated ? 'First update' : 'Post update',
            icon: Icons.edit_outlined,
            onPressed: onPost,
            color: HubTone.accent,
            size: AppButtonSize.compact,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: AppButton(
            key: const ValueKey('gem-handover'),
            label: pending ? 'Handover pending' : 'Hand over',
            variant: AppButtonVariant.tinted,
            onPressed: onHandover,
            color: HubTone.quiet,
            size: AppButtonSize.compact,
          ),
        ),
      ],
    );
  }

  Widget _timeline(int? gapDays) {
    final events = detail?.updates;
    if (events == null) {
      if (error != null) {
        return _Status(message: error!, onRetry: onRetry);
      }
      if (loading) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpace.xl),
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: HubTone.accent,
              ),
            ),
          ),
        );
      }
    }
    if (events == null || events.isEmpty) {
      return GemNeverUpdatedLine(
        key: const ValueKey('gem-no-updates'),
        listed: daysAgoSince(gem.listedAt, now),
      );
    }
    return GemTimeline(
      key: const ValueKey('gem-timeline'),
      events: events,
      gapDays: gapDays,
      onEdit: onEdit,
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message, style: HubType.body(AppColors.textMuted)),
        AppSpace.gapSm,
        AppButton(
          label: 'Try again',
          variant: AppButtonVariant.outline,
          onPressed: onRetry,
          size: AppButtonSize.compactSmall,
        ),
      ],
    );
  }
}
