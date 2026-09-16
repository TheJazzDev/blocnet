import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_styles.dart';
import 'package:flutter/material.dart';

/// The Hub's handover sheets: title (17), one muted paragraph, then the
/// sheet's own fields and actions. Scrolls when the keyboard is up.
class HandoverSheetFrame extends StatelessWidget {
  const HandoverSheetFrame({
    super.key,
    required this.title,
    required this.body,
    required this.children,
  });

  final String title;
  final String body;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: HubType.lead(AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text(body, style: HubType.meta(AppColors.zincMuted)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

/// A refusal from the backend, shown in place under the fields.
class HandoverSheetError extends StatelessWidget {
  const HandoverSheetError({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        key: const ValueKey('handover-error'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.error_outline_rounded,
                size: 15, color: AppColors.quietOrange),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message,
              style: HubType.meta(AppColors.quietOrange),
            ),
          ),
        ],
      ),
    );
  }
}
