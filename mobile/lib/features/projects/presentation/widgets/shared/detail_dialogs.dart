import 'package:blocnet/features/projects/presentation/widgets/project/project_details/project_details_dialog.dart';
import 'package:blocnet/features/projects/presentation/widgets/update/update_details/update_details_dialog.dart';
import 'package:flutter/material.dart';

/// Opens gem detail as a bottom-up dialog, the way `GemCard` does.
Future<void> showGemDetailsDialog(BuildContext context, String projectId) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    pageBuilder: (context, animation, secondaryAnimation) {
      return ProjectDetailsDialog(projectId: projectId);
    },
    transitionDuration: const Duration(milliseconds: 320),
    transitionBuilder: _slideUp(Curves.easeOutCubic),
  );
}

/// Opens update detail as a bottom-up dialog, the way `FeedCard` does.
Future<void> showUpdateDetailsDialog(BuildContext context, String updateId) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black.withValues(alpha: 0.75),
    pageBuilder: (context, _, __) => UpdateDetailsDialog(id: updateId),
    transitionDuration: const Duration(milliseconds: 280),
    transitionBuilder: _slideUp(Curves.easeOutCubic),
  );
}

RouteTransitionsBuilder _slideUp(Curve curve) {
  return (context, animation, secondaryAnimation, child) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: curve)),
      child: child,
    );
  };
}
