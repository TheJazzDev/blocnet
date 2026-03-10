import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/moderation/data/models/community_report_model.dart';
import 'package:blocnet/services/api/api_client.dart';
import 'package:flutter/material.dart';

class SubmitAppealScreen extends StatefulWidget {
  final CommunityReport report;

  const SubmitAppealScreen({
    required this.report,
    super.key,
  });

  @override
  State<SubmitAppealScreen> createState() => _SubmitAppealScreenState();
}

class _SubmitAppealScreenState extends State<SubmitAppealScreen> {
  final TextEditingController _reasonController = TextEditingController();
  final ApiClient _apiClient = ApiClient();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submitAppeal() async {
    if (_reasonController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please provide a reason for your appeal');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await _apiClient.post('/community/appeals', body: {
        'reportId': widget.report.id,
        'reason': _reasonController.text.trim(),
      });

      if (!mounted) return;

      // Show success message and go back
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Appeal submitted successfully'),
          backgroundColor: AppColors.successColor,
        ),
      );

      Navigator.of(context).pop(true); // Return true to indicate success
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        backgroundColor: AppColors.bgBase,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Submit Appeal',
          style: AppTypography.custom(
            color: AppColors.textPrimary,
            size: 16,
            weight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Report details card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Report Details',
                    style: AppTypography.custom(
                      color: AppColors.textPrimary,
                      size: 13,
                      weight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _InfoRow(
                    label: 'Report Type',
                    value: widget.report.targetTypeLabel,
                  ),
                  const SizedBox(height: 6),
                  _InfoRow(
                    label: 'Category',
                    value: widget.report.category,
                  ),
                  const SizedBox(height: 6),
                  _InfoRow(
                    label: 'Status',
                    value: widget.report.statusLabel,
                  ),
                  if (widget.report.reviewNotes != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Review Notes:',
                      style: AppTypography.custom(
                        color: AppColors.textMuted,
                        size: 11,
                        weight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.report.reviewNotes!,
                      style: AppTypography.custom(
                        color: AppColors.textSecondary,
                        size: 12,
                        weight: FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Appeal reason input
            Text(
              'Reason for Appeal',
              style: AppTypography.custom(
                color: AppColors.textPrimary,
                size: 13,
                weight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Explain why you believe this decision should be reconsidered. Be clear and specific.',
              style: AppTypography.custom(
                color: AppColors.textMuted,
                size: 11,
                weight: FontWeight.w400,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reasonController,
              maxLines: 8,
              maxLength: 2000,
              enabled: !_isSubmitting,
              style: AppTypography.custom(
                color: AppColors.textPrimary,
                size: 13,
                weight: FontWeight.w400,
              ),
              decoration: InputDecoration(
                hintText: 'Provide a detailed explanation...',
                hintStyle: AppTypography.custom(
                  color: AppColors.textMuted,
                  size: 13,
                  weight: FontWeight.w400,
                ),
                filled: true,
                fillColor: AppColors.bgSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderSubtle),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderSubtle),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary400, width: 2),
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error500.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error500.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 18,
                      color: AppColors.error500,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: AppTypography.custom(
                          color: AppColors.error500,
                          size: 12,
                          weight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitAppeal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary400,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Submit Appeal',
                        style: AppTypography.custom(
                          color: Colors.white,
                          size: 14,
                          weight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.custom(
            color: AppColors.textMuted,
            size: 11,
            weight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: AppTypography.custom(
            color: AppColors.textPrimary,
            size: 12,
            weight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
