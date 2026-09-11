import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/shared/widgets/app_button.dart';
import 'package:flutter/material.dart';

/// Icon, a short line about what is missing, a sentence about how to fix it,
/// and ideally something to press.
///
/// 150 files carry empty-state copy and almost none of them offer a next step,
/// which is finding F-19 in the UX tracker. [actionLabel] is here to make the
/// next step the easy thing to add rather than an afterthought.
///
/// ```dart
/// AppEmptyState(
///   icon: Icons.inbox_outlined,
///   title: 'No updates yet',
///   message: 'Follow a project and its updates land here.',
///   actionLabel: 'Discover projects',
///   onAction: () => goToDiscover(),
/// )
/// ```
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    required this.title,
    this.message,
    this.icon,
    this.actionLabel,
    this.onAction,
    this.compact = false,
    super.key,
  }) : _isError = false;

  /// The error twin: a warning tone and a retry affordance. Same layout, so a
  /// list that swaps between empty and failed does not jump.
  const AppEmptyState.error({
    required this.title,
    this.message,
    this.icon = Icons.error_outline_rounded,
    this.actionLabel = 'Try again',
    this.onAction,
    this.compact = false,
    super.key,
  }) : _isError = true;

  final String title;
  final String? message;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Tighter, for an empty state inside a card rather than a whole screen.
  final bool compact;

  final bool _isError;

  @override
  Widget build(BuildContext context) {
    final tint = _isError ? AppColors.error500 : AppColors.textFaint;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpace.xl,
        vertical: compact ? AppSpace.xl : AppSpace.xxxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: compact ? AppIcon.xl : AppIcon.xxl, color: tint),
            SizedBox(height: compact ? AppSpace.md : AppSpace.lg),
          ],
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppText.subtitle(AppColors.textSecondary),
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpace.xs),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: AppText.body(AppColors.textFaint),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            SizedBox(height: compact ? AppSpace.lg : AppSpace.xl),
            AppButton(
              label: actionLabel!,
              onPressed: onAction,
              variant: AppButtonVariant.secondary,
              size: AppButtonSize.small,
            ),
          ],
        ],
      ),
    );
  }
}
