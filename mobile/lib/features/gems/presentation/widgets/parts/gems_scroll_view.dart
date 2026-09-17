import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:flutter/material.dart';

/// Where a view's data stands.
enum GemsLoadState { loading, error, ready }

/// A pull-to-refresh list inside the screen gutter, with room at the bottom
/// for the composer button.
class GemsScrollView extends StatelessWidget {
  const GemsScrollView({
    super.key,
    required this.onRefresh,
    required this.children,
    this.storageKey,
  });

  final Future<void> Function() onRefresh;
  final List<Widget> children;
  final String? storageKey;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary500,
      backgroundColor: AppColors.bgSurface,
      onRefresh: onRefresh,
      child: ListView(
        key: storageKey == null ? null : PageStorageKey(storageKey),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          AppSpace.lg,
          AppSpace.lg,
          AppSpace.lg,
          MediaQuery.paddingOf(context).bottom + 96,
        ),
        children: children,
      ),
    );
  }
}
