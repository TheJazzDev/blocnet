import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/community/data/models/community_moderation_models.dart';
import 'package:blocnet/features/community/data/repositories/community_moderation_api_repository.dart';
import 'package:blocnet/features/moderation/presentation/widgets/common/mod_input_dialogs.dart';
import 'package:blocnet/features/moderation/presentation/widgets/common/mod_parts.dart';
import 'package:blocnet/features/moderation/presentation/widgets/common/mod_styles.dart';
import 'package:blocnet/features/moderation/presentation/widgets/reports/member_state_card.dart';
import 'package:blocnet/services/api/api_error.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:blocnet/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';

/// Opens the sanctions sheet for the member a report is about.
Future<void> showMemberActionsSheet(
  BuildContext context, {
  required CommunityModerationApiRepository repository,
  required CommunityModerationReport report,
  required String targetUserId,
  required bool canEscalate,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.bgSurface,
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
    builder: (_) => MemberActionsSheet(
      repository: repository,
      report: report,
      targetUserId: targetUserId,
      canEscalate: canEscalate,
    ),
  );
}

/// The member's standing and the sanctions this moderator may apply.
/// Suspend and restrict are for community admins and governance only.
class MemberActionsSheet extends StatefulWidget {
  const MemberActionsSheet({
    super.key,
    required this.repository,
    required this.report,
    required this.targetUserId,
    required this.canEscalate,
  });

  final CommunityModerationApiRepository repository;
  final CommunityModerationReport report;
  final String targetUserId;
  final bool canEscalate;

  @override
  State<MemberActionsSheet> createState() => _MemberActionsSheetState();
}

class _MemberActionsSheetState extends State<MemberActionsSheet> {
  CommunityModerationUserState? _state;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final state = await widget.repository.getUserState(widget.targetUserId);
      if (!mounted) return;
      setState(() => _state = state);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = describeApiError(
          error,
          fallback: 'Could not load this member.',
        );
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _run(
    Future<CommunityModerationUserState> Function() action,
    String success,
  ) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final updated = await action();
      if (!mounted) return;
      setState(() => _state = updated);
      AppSnackbar.showSuccess(context, success);
    } catch (error) {
      if (!mounted) return;
      AppSnackbar.showError(
        context,
        describeApiError(error, fallback: 'That did not go through.'),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String get _userId => widget.targetUserId;
  String get _reportId => widget.report.id;

  Future<void> _warn() async {
    final reason = await showModReasonDialog(
      context,
      title: 'Warn member',
      hint: 'What was wrong?',
      required: true,
      confirmLabel: 'Warn',
    );
    if (reason == null || reason.isEmpty) return;
    await _run(
      () => widget.repository.issueWarning(
        userId: _userId,
        reason: reason,
        reportId: _reportId,
      ),
      'Warning issued',
    );
  }

  Future<void> _mute() async {
    final input = await showModDurationDialog(
      context,
      title: 'Mute member',
      hint: 'Why mute?',
    );
    if (input == null) return;
    await _run(
      () => widget.repository.applyMute(
        userId: _userId,
        durationHours: input.hours,
        reason: input.reason,
        reportId: _reportId,
      ),
      'Mute applied',
    );
  }

  Future<void> _suspend() async {
    final input = await showModDurationDialog(
      context,
      title: 'Suspend member',
      hint: 'Why suspend?',
    );
    if (input == null) return;
    await _run(
      () => widget.repository.applySuspension(
        userId: _userId,
        durationHours: input.hours,
        reason: input.reason,
        reportId: _reportId,
      ),
      'Suspension applied',
    );
  }

  Future<void> _restrict() async {
    final input = await showModRestrictionDialog(context);
    if (input == null) return;
    await _run(
      () => widget.repository.applyRestrictions(
        userId: _userId,
        postingHours: input.postingHours,
        commentingHours: input.commentingHours,
        reason: input.reason,
        reportId: _reportId,
      ),
      'Restrictions updated',
    );
  }

  Future<void> _clear() async {
    final reason = await showModReasonDialog(
      context,
      title: 'Clear restrictions',
      hint: 'Why clear them?',
      required: true,
      confirmLabel: 'Clear',
    );
    if (reason == null || reason.isEmpty) return;
    await _run(
      () => widget.repository.clearRestrictions(
        userId: _userId,
        reason: reason,
        reportId: _reportId,
      ),
      'Restrictions cleared',
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          ModTone.gutter,
          AppSpace.md,
          ModTone.gutter,
          AppSpace.xl + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Grabber(),
              AppSpace.gapMd,
              Row(
                children: [
                  const Icon(
                    Icons.person_outline_rounded,
                    size: AppIcon.md,
                    color: ModTone.accent,
                  ),
                  AppSpace.wGapSm,
                  Text(
                    'Member actions',
                    style: AppText.subtitle(
                      AppColors.textPrimary,
                      weight: AppText.bold,
                    ),
                  ),
                ],
              ),
              AppSpace.gapLg,
              ..._body(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _body() {
    final state = _state;
    if (_loading) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpace.xl),
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: ModTone.accent,
            ),
          ),
        ),
      ];
    }
    if (_error != null || state == null) {
      return [
        AppEmptyState.error(
          compact: true,
          title: 'Member did not load',
          message: _error,
          onAction: _loadState,
        ),
      ];
    }
    final lock = _busy;
    return [
      MemberStateCard(state: state),
      AppSpace.gapLg,
      Row(
        children: [
          Expanded(
            child: AppButton(label: 'Warn', onPressed: lock ? null : _warn, variant: AppButtonVariant.outline, size: AppButtonSize.compact),
          ),
          AppSpace.wGapSm,
          Expanded(
            child: AppButton(label: 'Mute', onPressed: lock ? null : _mute, variant: AppButtonVariant.outline, size: AppButtonSize.compact),
          ),
        ],
      ),
      if (widget.canEscalate) ...[
        AppSpace.gapSm,
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Suspend',
                color: ModTone.accent,
                onPressed: lock ? null : _suspend,
                size: AppButtonSize.compact,
              ),
            ),
            AppSpace.wGapSm,
            Expanded(
              child: AppButton(
                label: 'Restrict',
                onPressed: lock ? null : _restrict,
                variant: AppButtonVariant.outline,
                size: AppButtonSize.compact,
              ),
            ),
          ],
        ),
        AppSpace.gapSm,
        AppButton(
          label: 'Clear restrictions',
          onPressed: lock ? null : _clear,
          variant: AppButtonVariant.outline,
          size: AppButtonSize.compact,
        ),
      ] else ...[
        AppSpace.gapMd,
        Text(
          'Suspend and restrict are for community admins.',
          style: ModText.meta(AppColors.textMuted),
        ),
      ],
    ];
  }
}

class _Grabber extends StatelessWidget {
  const _Grabber();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.borderMuted,
          borderRadius: AppRadius.full,
        ),
      ),
    );
  }
}
