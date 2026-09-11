import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:flutter/material.dart';

/// The bottom-sheet shell: grab handle, title row, optional close, content.
///
/// 23 call sites open a modal sheet and each builds its own chrome, which is
/// why the handle, the title size and the top radius differ between them. The
/// content is yours; everything around it is settled here.
///
/// Use [show] rather than calling `showModalBottomSheet` directly. It pins the
/// barrier colour, the top radius and `isScrollControlled`, and it keeps the
/// sheet clear of the keyboard, which is the bug most hand-rolled sheets have
/// when they contain a field.
///
/// ```dart
/// AppSheet.show<void>(
///   context: context,
///   title: 'Switch Space',
///   icon: Icons.swap_horiz_rounded,
///   builder: (_) => Column(children: spaces),
/// );
/// ```
class AppSheet extends StatelessWidget {
  const AppSheet({
    required this.child,
    this.title,
    this.icon,
    this.showClose = true,
    this.padding,
    super.key,
  });

  final Widget child;
  final String? title;
  final IconData? icon;
  final bool showClose;
  final EdgeInsetsGeometry? padding;

  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    String? title,
    IconData? icon,
    bool showClose = true,
    bool isDismissible = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: isDismissible,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (ctx) => AppSheet(
        title: title,
        icon: icon,
        showClose: showClose,
        child: builder(ctx),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadius.sheet,
        border: Border(
          top: BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          // Lifts the sheet above the keyboard when it holds a field.
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpace.md),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderMuted,
                  borderRadius: AppRadius.full,
                ),
              ),
              if (title != null) ...[
                const SizedBox(height: AppSpace.lg),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
                  child: Row(
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: AppIcon.md, color: AppColors.textMuted),
                        const SizedBox(width: AppSpace.md),
                      ],
                      Expanded(
                        child: Text(
                          title!,
                          style: AppText.title(AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (showClose)
                        GestureDetector(
                          onTap: () => Navigator.of(context).maybePop(),
                          behavior: HitTestBehavior.opaque,
                          child: const Padding(
                            padding: EdgeInsets.all(AppSpace.sm),
                            child: Icon(Icons.close_rounded, size: AppIcon.md),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.sm),
                Divider(color: AppColors.borderSubtle, height: 1),
              ],
              Flexible(
                child: Padding(
                  padding: padding ??
                      const EdgeInsets.fromLTRB(
                        AppSpace.lg,
                        AppSpace.lg,
                        AppSpace.lg,
                        AppSpace.xl,
                      ),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
