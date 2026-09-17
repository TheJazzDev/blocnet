import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/profile/presentation/widgets/common/profile_row_group.dart';
import 'package:flutter/material.dart';

/// A tab's rows in one card. Shows the first [collapsedCount] and a
/// "Show all" row that expands the rest in place.
class ProfileTabList extends StatefulWidget {
  const ProfileTabList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.collapsedCount = 5,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final int collapsedCount;

  @override
  State<ProfileTabList> createState() => _ProfileTabListState();
}

class _ProfileTabListState extends State<ProfileTabList> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final total = widget.itemCount;
    final canExpand = total > widget.collapsedCount;
    final shown = _expanded || !canExpand ? total : widget.collapsedCount;

    return ProfileRowGroup(
      children: [
        for (var i = 0; i < shown; i++) widget.itemBuilder(context, i),
        if (canExpand)
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.lg,
                vertical: AppSpace.md,
              ),
              child: Text(
                _expanded ? 'Show less' : 'Show all ($total)',
                style: AppText.label(AppColors.primary400,
                    weight: AppText.bold),
              ),
            ),
          ),
      ],
    );
  }
}
