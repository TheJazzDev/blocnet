import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/engagement/data/models/edge_brief_model.dart';
import 'package:blocnet/features/engagement/data/models/edge_explain_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/edge/edge_empty_state.dart';
import 'package:blocnet/services/edge/edge_engine_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EdgeEnginePage extends StatelessWidget {
  const EdgeEnginePage({
    super.key,
    required this.onAction,
    required this.onExplain,
    this.onFollowProjects,
  });

  final Future<void> Function(EdgeBriefDecision decision, String action)
      onAction;
  final Future<void> Function(EdgeBriefDecision decision) onExplain;

  /// Invoked by the empty state's "Follow gems" button. The launcher
  /// owns navigation (pop this page, switch the shell to Discover).
  final VoidCallback? onFollowProjects;

  @override
  Widget build(BuildContext context) {
    final edgeStore = context.watch<EdgeEngineStore>();
    final summary = edgeStore.brief;
    final hasNoSignals = summary != null &&
        !edgeStore.isFetching &&
        summary.totalSignals == 0 &&
        summary.topDecisions.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        title: Text(
          'Edge Engine',
          style: AppTypography.custom(
            color: AppColors.textPrimary,
            size: AppText.titleSize,
            weight: FontWeight.w700,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary500,
        backgroundColor: AppColors.bgSurface,
        onRefresh: edgeStore.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.lg, AppSpace.lg, AppSpace.xl),
          children: [
            EdgeBriefCard(
              brief: summary,
              isLoading: edgeStore.isFetching && summary == null,
              onAction: onAction,
              onExplain: onExplain,
              useCardChrome: false,
            ),
            if (hasNoSignals) ...[
              const SizedBox(height: AppSpace.lg),
              EdgeEmptyState(onFollowProjects: onFollowProjects),
            ],
          ],
        ),
      ),
    );
  }
}

class EdgeBriefCard extends StatelessWidget {
  const EdgeBriefCard({
    super.key,
    required this.brief,
    required this.isLoading,
    required this.onAction,
    required this.onExplain,
    this.useCardChrome = true,
  });

  final EdgeBriefResponse? brief;
  final bool isLoading;
  final Future<void> Function(EdgeBriefDecision decision, String action)
      onAction;
  final Future<void> Function(EdgeBriefDecision decision) onExplain;
  final bool useCardChrome;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpace.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.bgSurface,
              AppColors.bgSurface.withValues(alpha: 0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(AppRadius.lgValue),
          border: Border.all(
            color: AppColors.borderSubtle.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary400,
              ),
            ),
            const SizedBox(width: AppSpace.md),
            Text(
              'Loading edge brief...',
              style: AppTypography.custom(
                color: AppColors.textMuted,
                size: AppText.labelSize,
                weight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final summary = brief;
    if (summary == null) {
      return const SizedBox.shrink();
    }

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpace.sm),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary500.withValues(alpha: 0.2),
                    AppColors.primary500.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppRadius.smValue),
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                size: AppIcon.sm,
                color: AppColors.primary400,
              ),
            ),
            const SizedBox(width: AppSpace.md),
            Text(
              'BLOCNET EDGE ENGINE',
              style: AppTypography.custom(
                color: AppColors.textFaint,
                size: AppText.captionSize,
                weight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.md),
        Text(
          summary.headline.trim().isEmpty
              ? 'Edge intelligence is ready.'
              : summary.headline,
          style: AppTypography.custom(
            color: AppColors.textPrimary,
            size: AppText.bodySize,
            weight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpace.md),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            BriefMetricChip(
              label: '${summary.totalSignals} signals',
            ),
            BriefMetricChip(
              label: '${summary.recommendedNowCount} act now',
            ),
            BriefMetricChip(
              label: '${summary.watchCount} watch',
            ),
          ],
        ),
        if (summary.topDecisions.isNotEmpty) ...[
          const SizedBox(height: AppSpace.lg),
          ...summary.topDecisions.take(3).map((decision) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.md),
              child: EdgeDecisionRow(
                decision: decision,
                onAction: onAction,
                onExplain: onExplain,
              ),
            );
          }),
        ],
      ],
    );

    if (!useCardChrome) {
      return content;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.bgSurface,
            AppColors.bgSurface.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lgValue),
        border: Border.all(
          color: AppColors.primary500.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary500.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: content,
    );
  }
}

class BriefMetricChip extends StatelessWidget {
  const BriefMetricChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.xs),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary500.withValues(alpha: 0.15),
            AppColors.primary500.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.smValue),
        border: Border.all(
          color: AppColors.primary500.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: AppTypography.custom(
          color: AppColors.primary400,
          size: AppText.captionSize,
          weight: FontWeight.w700,
        ),
      ),
    );
  }
}

class EdgeDecisionRow extends StatelessWidget {
  const EdgeDecisionRow({
    super.key,
    required this.decision,
    required this.onAction,
    required this.onExplain,
  });

  final EdgeBriefDecision decision;
  final Future<void> Function(EdgeBriefDecision decision, String action)
      onAction;
  final Future<void> Function(EdgeBriefDecision decision) onExplain;

  @override
  Widget build(BuildContext context) {
    final urgencyColor = _urgencyColor(decision.urgency);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.bgElevated,
            AppColors.bgElevated.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.mdValue),
        border: Border.all(
          color: urgencyColor.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            decision.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.custom(
              color: AppColors.textPrimary,
              size: AppText.labelSize,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: AppSpace.hair),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      urgencyColor.withValues(alpha: 0.2),
                      urgencyColor.withValues(alpha: 0.12),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.smValue),
                  border: Border.all(
                    color: urgencyColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  decision.urgency.toUpperCase(),
                  style: AppTypography.custom(
                    color: urgencyColor,
                    size: AppText.captionSize,
                    weight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Text(
                '${decision.projectName} · ${decision.edgeScore.toStringAsFixed(2)}',
                style: AppTypography.custom(
                  color: AppColors.textMuted,
                  size: AppText.captionSize,
                  weight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Row(
            children: [
              ActionChip(
                label: 'Act',
                action: 'act',
                recommendedAction: decision.recommendedAction,
                onTap: () => onAction(decision, 'act'),
              ),
              const SizedBox(width: AppSpace.sm),
              ActionChip(
                label: 'Watch',
                action: 'watch',
                recommendedAction: decision.recommendedAction,
                onTap: () => onAction(decision, 'watch'),
              ),
              const SizedBox(width: AppSpace.sm),
              ActionChip(
                label: 'Ignore',
                action: 'ignore',
                recommendedAction: decision.recommendedAction,
                onTap: () => onAction(decision, 'ignore'),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => onExplain(decision),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: AppSpace.xs),
                  decoration: BoxDecoration(
                    color: AppColors.primary500.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.smValue),
                  ),
                  child: Text(
                    'Why?',
                    style: AppTypography.custom(
                      color: AppColors.primary400,
                      size: AppText.captionSize,
                      weight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _urgencyColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'high':
        return AppColors.error500;
      case 'medium':
        return AppColors.warning500;
      default:
        return AppColors.primary400;
    }
  }
}

class ActionChip extends StatelessWidget {
  const ActionChip({
    super.key,
    required this.label,
    required this.action,
    required this.recommendedAction,
    required this.onTap,
  });

  final String label;
  final String action;
  final String recommendedAction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isRecommended = action == recommendedAction;
    final color = _actionColor(action);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm),
        decoration: BoxDecoration(
          gradient: isRecommended
              ? LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.25),
                    color.withValues(alpha: 0.15),
                  ],
                )
              : null,
          color: isRecommended ? null : color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadius.smValue),
          border: Border.all(
            color: color.withValues(alpha: isRecommended ? 0.4 : 0.3),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.custom(
            color: color,
            size: AppText.captionSize,
            weight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Color _actionColor(String value) {
    switch (value) {
      case 'act':
        return AppColors.successColor;
      case 'watch':
        return AppColors.warning500;
      case 'ignore':
      default:
        return AppColors.textMuted;
    }
  }
}

class EdgeExplainSheet extends StatelessWidget {
  const EdgeExplainSheet({super.key, required this.explain});

  final EdgeExplainResponse explain;

  @override
  Widget build(BuildContext context) {
    final update = explain.update!;
    final details = explain.explanation!;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.md, AppSpace.lg, AppSpace.xl),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderMuted,
                    borderRadius: BorderRadius.circular(AppRadius.fullValue),
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.md),
              Text(
                'Why BEE ranked this',
                style: AppTypography.custom(
                  color: AppColors.textPrimary,
                  size: AppText.subtitleSize,
                  weight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              Text(
                update.title,
                style: AppTypography.custom(
                  color: AppColors.textSecondary,
                  size: AppText.labelSize,
                  weight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              Text(
                '${update.projectName} · ${update.urgency.toUpperCase()}',
                style: AppTypography.custom(
                  color: AppColors.textMuted,
                  size: AppText.captionSize,
                  weight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppSpace.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpace.md),
                decoration: BoxDecoration(
                  color: AppColors.bgElevated,
                  borderRadius: BorderRadius.circular(AppRadius.mdValue),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Text(
                  details.narrative.trim().isEmpty
                      ? details.explanationPreview
                      : details.narrative,
                  style: AppTypography.custom(
                    color: AppColors.textSecondary,
                    size: AppText.labelSize,
                    weight: FontWeight.w500,
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.md),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: details.reasonCodes.map((reason) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: AppSpace.xs),
                    decoration: BoxDecoration(
                      color: AppColors.bgElevated,
                      borderRadius: BorderRadius.circular(AppRadius.fullValue),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Text(
                      reason,
                      style: AppTypography.custom(
                        color: AppColors.textMuted,
                        size: AppText.captionSize,
                        weight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpace.lg),
              ExplainMetricRow(label: 'Edge score', value: details.edgeScore),
              ExplainMetricRow(
                  label: 'Urgency component',
                  value: details.components.urgency),
              ExplainMetricRow(
                  label: 'Recency component',
                  value: details.components.recency),
              ExplainMetricRow(
                  label: 'Relevance component',
                  value: details.components.relevance),
              ExplainMetricRow(
                  label: 'Novelty component',
                  value: details.components.novelty),
              ExplainMetricRow(
                  label: 'Penalty component',
                  value: details.components.penalties),
            ],
          ),
        ),
      ),
    );
  }
}

class ExplainMetricRow extends StatelessWidget {
  const ExplainMetricRow({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.custom(
                color: AppColors.textMuted,
                size: AppText.captionSize,
                weight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value.toStringAsFixed(2),
            style: AppTypography.custom(
              color: AppColors.textPrimary,
              size: AppText.labelSize,
              weight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
