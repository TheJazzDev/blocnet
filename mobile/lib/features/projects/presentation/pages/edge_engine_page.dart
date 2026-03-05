import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/engagement/data/models/edge_brief_model.dart';
import 'package:blocnet/features/engagement/data/models/edge_explain_model.dart';
import 'package:blocnet/services/edge/edge_engine_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EdgeEnginePage extends StatelessWidget {
  const EdgeEnginePage({
    super.key,
    required this.onAction,
    required this.onExplain,
  });

  final Future<void> Function(EdgeBriefDecision decision, String action)
      onAction;
  final Future<void> Function(EdgeBriefDecision decision) onExplain;

  @override
  Widget build(BuildContext context) {
    final edgeStore = context.watch<EdgeEngineStore>();
    final summary = edgeStore.brief;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        title: Text(
          'Edge Engine',
          style: AppTypography.custom(
            color: AppColors.textPrimary,
            size: 18,
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            EdgeBriefCard(
              brief: summary,
              isLoading: edgeStore.isFetching && summary == null,
              onAction: onAction,
              onExplain: onExplain,
              useCardChrome: false,
            ),
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.bgSurface,
              AppColors.bgSurface.withValues(alpha: 0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
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
            const SizedBox(width: 12),
            Text(
              'Loading edge brief...',
              style: AppTypography.custom(
                color: AppColors.textMuted,
                size: 13,
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
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary500.withValues(alpha: 0.2),
                    AppColors.primary500.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 16,
                color: AppColors.primary400,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'BLOCNET EDGE ENGINE',
              style: AppTypography.custom(
                color: AppColors.textFaint,
                size: 10,
                weight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          summary.headline.trim().isEmpty
              ? 'Edge intelligence is ready.'
              : summary.headline,
          style: AppTypography.custom(
            color: AppColors.textPrimary,
            size: 14,
            weight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
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
          const SizedBox(height: 14),
          ...summary.topDecisions.take(3).map((decision) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.bgSurface,
            AppColors.bgSurface.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary500.withValues(alpha: 0.15),
            AppColors.primary500.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primary500.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: AppTypography.custom(
          color: AppColors.primary400,
          size: 11,
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.bgElevated,
            AppColors.bgElevated.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
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
              size: 13,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      urgencyColor.withValues(alpha: 0.2),
                      urgencyColor.withValues(alpha: 0.12),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: urgencyColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  decision.urgency.toUpperCase(),
                  style: AppTypography.custom(
                    color: urgencyColor,
                    size: 9,
                    weight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${decision.projectName} · ${decision.edgeScore.toStringAsFixed(2)}',
                style: AppTypography.custom(
                  color: AppColors.textMuted,
                  size: 11,
                  weight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              ActionChip(
                label: 'Act',
                action: 'act',
                recommendedAction: decision.recommendedAction,
                onTap: () => onAction(decision, 'act'),
              ),
              const SizedBox(width: 6),
              ActionChip(
                label: 'Watch',
                action: 'watch',
                recommendedAction: decision.recommendedAction,
                onTap: () => onAction(decision, 'watch'),
              ),
              const SizedBox(width: 6),
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
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary500.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Why?',
                    style: AppTypography.custom(
                      color: AppColors.primary400,
                      size: 10,
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withValues(alpha: isRecommended ? 0.4 : 0.3),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.custom(
            color: color,
            size: 11,
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
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
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
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Why BEE ranked this',
                style: AppTypography.custom(
                  color: AppColors.textPrimary,
                  size: 16,
                  weight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                update.title,
                style: AppTypography.custom(
                  color: AppColors.textSecondary,
                  size: 13,
                  weight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${update.projectName} · ${update.urgency.toUpperCase()}',
                style: AppTypography.custom(
                  color: AppColors.textMuted,
                  size: 11,
                  weight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.bgElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Text(
                  details.narrative.trim().isEmpty
                      ? details.explanationPreview
                      : details.narrative,
                  style: AppTypography.custom(
                    color: AppColors.textSecondary,
                    size: 12,
                    weight: FontWeight.w500,
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: details.reasonCodes.map((reason) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.bgElevated,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Text(
                      reason,
                      style: AppTypography.custom(
                        color: AppColors.textMuted,
                        size: 10,
                        weight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.custom(
                color: AppColors.textMuted,
                size: 11,
                weight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value.toStringAsFixed(2),
            style: AppTypography.custom(
              color: AppColors.textPrimary,
              size: 12,
              weight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
