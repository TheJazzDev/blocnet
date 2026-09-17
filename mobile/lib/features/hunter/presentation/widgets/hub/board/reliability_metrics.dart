import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/hunter/data/models/hunter_reliability_model.dart';
import 'package:blocnet/features/hunter/domain/hub_format.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_styles.dart';
import 'package:flutter/material.dart';

/// The three figures under the pips, already worded.
@immutable
class ReliabilityMetricValues {
  const ReliabilityMetricValues({
    required this.response,
    required this.cadence,
    required this.waiting,
  });

  /// `4 of 4`, or a share on a backend without the counts. An em dash when
  /// nobody has asked yet: there is nothing to answer, which is not zero.
  factory ReliabilityMetricValues.from(HunterReliability r) {
    final asked = r.responseAsked;
    final answered = r.responseAnswered;
    final String response;
    if (asked != null && answered != null) {
      response = asked == 0 ? '—' : '$answered of $asked';
    } else if (r.response != null) {
      response = '${(r.response! * 100).round()}%';
    } else {
      response = '—';
    }
    final cadenceDays = r.cadenceDays;
    return ReliabilityMetricValues(
      response: response,
      cadence: cadenceDays == null ? '—' : counted(cadenceDays.round(), 'day'),
      waiting: groupedCount(r.membersWaiting),
    );
  }

  final String response;
  final String cadence;
  final String waiting;
}

/// `RESPONSE 4 of 4 · CADENCE 5 days · WAITING 0`, as the old profile's
/// small bordered trust chips.
class ReliabilityMetrics extends StatelessWidget {
  const ReliabilityMetrics({super.key, required this.values});

  final ReliabilityMetricValues values;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.md + 2),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          _Metric(value: values.response, label: 'Response'),
          _Metric(value: values.cadence, label: 'Cadence'),
          _Metric(value: values.waiting, label: 'Waiting'),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: AppRadius.sm,
        border: Border.all(color: AppColors.borderMuted),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            label.toUpperCase(),
            style: HubType.caps(
              AppColors.textFaint,
              weight: AppText.semibold,
              tracking: 0.4,
            ),
          ),
          AppSpace.wGapXs,
          Text(
            value,
            style: AppText.label(AppColors.textPrimary, weight: AppText.bold)
                .merge(AppText.tabular),
          ),
        ],
      ),
    );
  }
}
