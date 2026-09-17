import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';

enum _StatusTone { warning, success, error }

/// States of the Become-a-Hunter flow that are not the form itself:
/// pending review, approved (role still propagating), not approved (the
/// form is shown again beneath it), or the role already granted.
///
/// A flat card: tinted icon square, title, an outlined status pill, and a
/// short line. The colour lives in the icon and the pill, not the border.
class BecomeHunterStatusCard extends StatelessWidget {
  const BecomeHunterStatusCard.pending({super.key})
      : _icon = Icons.hourglass_top_rounded,
        _title = 'Application sent',
        _status = 'In review',
        _body = 'The team reviews applications within a few days. '
            'You get a notification either way.',
        _tone = _StatusTone.warning,
        _actionLabel = null,
        _onAction = null;

  const BecomeHunterStatusCard.approved({super.key})
      : _icon = Icons.task_alt_rounded,
        _title = 'Application approved',
        _status = 'Approved',
        _body = 'Hunter tools appear once the role reaches your account, '
            'usually within a minute. Reopen the app if it takes longer.',
        _tone = _StatusTone.success,
        _actionLabel = null,
        _onAction = null;

  const BecomeHunterStatusCard.rejected({super.key})
      : _icon = Icons.info_outline_rounded,
        _title = 'Last application not approved',
        _status = 'Not approved',
        _body = 'You can update your answer below and apply again.',
        _tone = _StatusTone.error,
        _actionLabel = null,
        _onAction = null;

  const BecomeHunterStatusCard.alreadyHunter({
    super.key,
    required VoidCallback onOpenHunterSpace,
  })  : _icon = Icons.verified_rounded,
        _title = 'You are a Hunter',
        _status = 'Hunter',
        _body = 'Your Hub, updates and tips are in Hunter space.',
        _tone = _StatusTone.success,
        _actionLabel = 'Open Hunter space',
        _onAction = onOpenHunterSpace;

  final IconData _icon;
  final String _title;
  final String _status;
  final String _body;
  final _StatusTone _tone;
  final String? _actionLabel;
  final VoidCallback? _onAction;

  @override
  Widget build(BuildContext context) {
    final accent = switch (_tone) {
      _StatusTone.warning => AppColors.warning500,
      _StatusTone.success => AppColors.successColor,
      _StatusTone.error => AppColors.tagWarning,
    };

    return AppSurface(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: AppRadius.md,
                ),
                child: Icon(_icon, size: AppIcon.md, color: accent),
              ),
              AppSpace.wGapMd,
              Expanded(
                child: Text(
                  _title,
                  style: AppText.body(
                    AppColors.textPrimary,
                    weight: AppText.bold,
                  ),
                ),
              ),
              AppSpace.wGapSm,
              AppPill(
                label: _status,
                color: accent,
                dense: true,
                uppercase: true,
              ),
            ],
          ),
          AppSpace.gapMd,
          Text(_body, style: AppText.body(AppColors.textMuted)),
          if (_actionLabel != null) ...[
            AppSpace.gapLg,
            AppButton(
              label: _actionLabel,
              onPressed: _onAction,
              fullWidth: true,
            ),
          ],
        ],
      ),
    );
  }
}
