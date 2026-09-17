import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_styles.dart';
import 'package:flutter/material.dart';

/// The Hub's handover sheets: title (16), one muted paragraph, then the
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
          AppSpace.gapSm,
          Text(body, style: HubType.body(AppColors.textMuted)),
          AppSpace.gapLg,
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
      padding: const EdgeInsets.only(top: AppSpace.sm),
      child: Row(
        key: const ValueKey('handover-error'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.error_outline_rounded,
                size: AppIcon.sm, color: HubTone.quiet),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message,
              style: HubType.meta(HubTone.quiet),
            ),
          ),
        ],
      ),
    );
  }
}
