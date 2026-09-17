import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/gems/presentation/widgets/parts/gems_button.dart';
import 'package:blocnet/features/gems/presentation/widgets/parts/gems_tone.dart';
import 'package:blocnet/features/hunter/domain/hub_format.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_styles.dart';
import 'package:blocnet/features/projects/presentation/widgets/home/home_panel.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';

/// A quiet gem: how long it has been, and *Ask* for followers (only
/// followers may ask).
class GemQuietNotice extends StatelessWidget {
  const GemQuietNotice({
    super.key,
    required this.days,
    required this.handle,
    required this.onAsk,
  });

  final int days;
  final String? handle;

  /// Null when the member does not follow the gem.
  final VoidCallback? onAsk;

  @override
  Widget build(BuildContext context) {
    return HomePanel(
      key: const ValueKey('gem-quiet-notice'),
      margin: const EdgeInsets.only(bottom: AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppPill.caps(label: 'Quiet', color: GemsTone.quiet),
              AppSpace.wGapSm,
              Expanded(
                child: Text(
                  'No update for ${counted(days, 'day')}',
                  style: HubType.meta(
                    AppColors.textSecondary,
                    weight: AppText.semibold,
                  ),
                ),
              ),
            ],
          ),
          if (onAsk != null) ...[
            AppSpace.gapMd,
            GemsButton(
              key: const ValueKey('gem-page-ask'),
              label: handle == null ? 'Ask for an update' : 'Ask $handle',
              icon: Icons.campaign_outlined,
              filled: false,
              expand: true,
              onTap: onAsk,
            ),
          ],
        ],
      ),
    );
  }
}
