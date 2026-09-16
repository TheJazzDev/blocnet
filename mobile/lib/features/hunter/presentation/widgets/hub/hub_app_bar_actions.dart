import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/hunter/presentation/hub_navigation.dart';
import 'package:flutter/material.dart';

/// The Hub's `history` icon in the shared app bar (D5): opens *My updates*.
/// Sized like the shared bar's minimal icons.
class HubHistoryAction extends StatelessWidget {
  const HubHistoryAction({super.key});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'My updates',
      child: Semantics(
        button: true,
        label: 'My updates',
        child: GestureDetector(
          key: const ValueKey('hub-history'),
          onTap: () => HubNavigation.openHistory(context),
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(
              Icons.history_rounded,
              size: 21,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
