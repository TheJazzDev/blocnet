import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:flutter/material.dart';

/// Underlined, left-aligned tab labels for the profile tabs.
class ProfileTabBar extends StatelessWidget {
  const ProfileTabBar({
    super.key,
    required this.tabs,
    required this.activeIndex,
    required this.onChanged,
    required this.accent,
  });

  final List<String> tabs;
  final int activeIndex;
  final ValueChanged<int> onChanged;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++)
            _Tab(
              label: tabs[i],
              active: i == activeIndex,
              accent: accent,
              onTap: () => onChanged(i),
            ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.active,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final bool active;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: active,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 44,
          margin: const EdgeInsets.only(right: AppSpace.xl),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? accent : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
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
