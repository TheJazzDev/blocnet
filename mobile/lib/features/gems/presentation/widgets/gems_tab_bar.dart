import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/gems/domain/gems_tab.dart';
import 'package:flutter/material.dart';

/// Discover · Your board · Hunters, underlined in the space accent.
class GemsTabBar extends StatelessWidget {
  const GemsTabBar({super.key, required this.active, required this.onSelect});

  final GemsTab active;
  final ValueChanged<GemsTab> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: const BoxDecoration(
        color: AppColors.bgBase,
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        children: [
          for (final tab in GemsTab.values)
            Expanded(
              child: _Tab(
                tab: tab,
                active: tab == active,
                onTap: () => onSelect(tab),
              ),
            ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.tab, required this.active, required this.onTap});

  final GemsTab tab;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.primary500;
    return Semantics(
      selected: active,
      button: true,
      child: GestureDetector(
        key: ValueKey('gems-tab-${tab.name}'),
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? accent : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            tab.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.body(
              active ? accent : AppColors.textFaint,
              weight: active ? AppText.semibold : AppText.medium,
            ),
          ),
        ),
      ),
    );
  }
}
