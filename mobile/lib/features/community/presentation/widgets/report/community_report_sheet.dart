import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/community/data/models/community_moderation_models.dart';
import 'package:blocnet/features/community/data/repositories/community_moderation_api_repository.dart';
import 'package:blocnet/features/community/presentation/widgets/report/community_report_parts.dart';
import 'package:blocnet/services/api/api_error.dart';
import 'package:blocnet/shared/widgets/app_sheet.dart';
import 'package:flutter/material.dart';

/// Opens the report sheet and, once a report is sent, confirms it with a
/// shortcut to My reports.
Future<void> openCommunityReportSheet(
  BuildContext context, {
  required CommunityReportTargetType targetType,
  required String targetId,
  required String content,
  CommunityModerationApiRepository? repository,
}) async {
  final sent = await AppSheet.show<bool>(
    context: context,
    title: 'Report ${targetType.label.toLowerCase()}',
    icon: Icons.flag_outlined,
    builder: (_) => CommunityReportSubmissionSheet(
      targetType: targetType,
      targetId: targetId,
      contentPreview: content.trim(),
      repository: repository,
    ),
  );
  if (sent == true && context.mounted) {
    showCommunityReportSent(context);
  }
}

/// The body of the report sheet: what is being reported, a reason, optional
/// details, and Send.
class CommunityReportSubmissionSheet extends StatefulWidget {
  const CommunityReportSubmissionSheet({
    super.key,
    required this.targetType,
    required this.targetId,
    required this.contentPreview,
    this.repository,
  });

  final CommunityReportTargetType targetType;
  final String targetId;
  final String contentPreview;
  final CommunityModerationApiRepository? repository;

  @override
  State<CommunityReportSubmissionSheet> createState() =>
      _CommunityReportSubmissionSheetState();
}

class _CommunityReportSubmissionSheetState
    extends State<CommunityReportSubmissionSheet> {
  static const int _maxDetails = 1000;

  late final CommunityModerationApiRepository _repository =
      widget.repository ?? CommunityModerationApiRepository();
  final _detailsController = TextEditingController();

  CommunityReportReason? _reason;
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _reason;
    if (reason == null) return;
    final details = _detailsController.text.trim();
    if (reason == CommunityReportReason.other && details.isEmpty) {
      setState(() => _error = 'Add a few words about the problem');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await _repository.createReport(
        CreateCommunityReportRequest(
          targetType: widget.targetType,
          targetId: widget.targetId,
          reason: reason.label,
          details: details.isEmpty ? null : details,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = describeApiError(error, fallback: 'Could not send report');
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final needsDetails = _reason == CommunityReportReason.other;
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.contentPreview.isNotEmpty) ...[
            CommunityReportPreview(text: widget.contentPreview),
            const SizedBox(height: AppSpace.lg),
          ],
          const CommunityReportLabel('Reason'),
          const SizedBox(height: AppSpace.xs),
          for (final reason in CommunityReportReason.values)
            CommunityReportReasonRow(
              label: reason.label,
              selected: _reason == reason,
              onTap: _isSubmitting
                  ? null
                  : () => setState(() {
                        _reason = reason;
                        _error = null;
                      }),
            ),
          const SizedBox(height: AppSpace.lg),
          CommunityReportLabel(needsDetails ? 'Details' : 'Details (optional)'),
          const SizedBox(height: AppSpace.sm),
          CommunityReportDetailsField(
            controller: _detailsController,
            enabled: !_isSubmitting,
            maxLength: _maxDetails,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpace.sm),
            Text(
              _error!,
              style: AppTypography.custom(
                color: AppColors.tagWarning,
                size: AppText.labelSize,
                weight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: AppSpace.sm),
          Text(
            'Only moderators see who sent a report.',
            style: AppTypography.custom(
              color: AppColors.textFaint,
              size: AppText.labelSize,
              weight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          CommunityReportSendButton(
            isSubmitting: _isSubmitting,
            onPressed: _reason == null || _isSubmitting ? null : _submit,
          ),
        ],
      ),
    );
  }
}
