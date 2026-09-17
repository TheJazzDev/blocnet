import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/hunter/domain/hub_format.dart';
import 'package:blocnet/features/profile/domain/reliability_summary.dart';
import 'package:blocnet/features/profile/presentation/widgets/common/reliability_line.dart';
import 'package:blocnet/features/profile/presentation/widgets/section_label.dart';
import 'package:blocnet/services/hunter/hunter_board_store.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// A hunter's reliability on their public profile, once and compactly:
/// standing, current gems, and response / cadence. Hides itself when the
/// read fails rather than showing zeros.
class PublicProfileReliability extends StatefulWidget {
  const PublicProfileReliability({super.key, required this.profileId});

  final String profileId;

  @override
  State<PublicProfileReliability> createState() =>
      _PublicProfileReliabilityState();
}

class _PublicProfileReliabilityState extends State<PublicProfileReliability> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<HunterBoardStore?>()?.loadReliability(widget.profileId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final r = context.watch<HunterBoardStore?>()?.reliabilityFor(
          widget.profileId,
        );
    if (r == null) return const SizedBox.shrink();

    final summary = ReliabilitySummary.fromReliability(r);
    final scored = summary.tone != StandingTone.unscored;
    final asked = r.responseAsked;
    final answered = r.responseAnswered;
    final response = asked != null && answered != null && asked > 0
        ? '$answered of $asked'
        : null;
    final cadence =
        r.cadenceDays == null ? null : counted(r.cadenceDays!.round(), 'day');
    final facts = [
      if (response != null) 'Response $response',
      if (cadence != null) 'Every $cadence',
      '${r.updates30d} updates · 30d',
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Reliability', icon: Icons.verified_outlined),
        AppSpace.gapSm,
        AppRowGroup(
          children: [
            Padding(
              padding: AppSpace.card,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ReliabilityLine(summary: summary),
                  if (scored) ...[
                    AppSpace.gapSm,
                    Text(
                      facts,
                      style: AppText.label(AppColors.textFaint,
                          weight: AppText.regular),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
