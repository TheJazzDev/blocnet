import 'package:blocnet/app/theme.dart';
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

/// `4 of 4 RESPONSE · 5 days CADENCE · 0 WAITING` under a hairline.
class ReliabilityMetrics extends StatelessWidget {
  const ReliabilityMetrics({super.key, required this.values});

  final ReliabilityMetricValues values;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.only(top: 14),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
        ),
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 8,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: HubType.lead(AppColors.zincStrong)),
        Text(
          label.toUpperCase(),
          style: HubType.caps(AppColors.zincCaption),
        ),
      ],
    );
  }
}
