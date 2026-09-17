import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/moderation/presentation/widgets/common/mod_styles.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';

/// A queue's list with its loading, failed and empty states. Every state
/// can be pulled to refresh, so an empty or failed queue is never a dead end.
class ModQueueBody extends StatelessWidget {
  const ModQueueBody({
    super.key,
    required this.isLoading,
    required this.error,
    required this.itemCount,
    required this.itemBuilder,
    required this.onRefresh,
    required this.errorTitle,
    required this.emptyTitle,
    required this.emptyIcon,
    this.emptyMessage,
  });

  final bool isLoading;

  /// A readable message; shown only when there is nothing to list.
  final String? error;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final Future<void> Function() onRefresh;
  final String errorTitle;
  final String emptyTitle;
  final IconData emptyIcon;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (isLoading && itemCount == 0) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: ModTone.accent,
          ),
        ),
      );
    }
    final Widget content;
    if (itemCount == 0) {
      content = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (error != null)
            AppEmptyState.error(
              title: errorTitle,
              message: error,
              onAction: onRefresh,
            )
          else
            AppEmptyState(
              icon: emptyIcon,
              title: emptyTitle,
              message: emptyMessage,
            ),
        ],
      );
    } else {
      content = ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          ModTone.gutter,
          AppSpace.lg,
          ModTone.gutter,
          AppSpace.xl,
        ),
        itemCount: itemCount,
        itemBuilder: itemBuilder,
        separatorBuilder: (_, __) => AppSpace.gapMd,
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: ModTone.accent,
      child: content,
    );
  }
}
