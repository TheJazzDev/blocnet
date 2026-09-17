import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';

/// "What we look for": three rows in one card, split by hairlines.
class BecomeHunterCriteria extends StatelessWidget {
  const BecomeHunterCriteria({super.key});

  static const _items = [
    (Icons.search_rounded, 'You research a project before posting.'),
    (Icons.forum_outlined, 'You are active and your comments add signal.'),
    (Icons.schedule_rounded, 'You can post updates on a steady schedule.'),
  ];

  @override
  Widget build(BuildContext context) {
    return AppSurface.flush(
      width: double.infinity,
      child: Column(
        children: [
          for (var i = 0; i < _items.length; i++) ...[
            if (i > 0)
              Divider(height: 1, thickness: 1, color: AppColors.borderSubtle),
            _CriterionRow(icon: _items[i].$1, text: _items[i].$2),
          ],
        ],
      ),
    );
  }
}

class _CriterionRow extends StatelessWidget {
  const _CriterionRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpace.row,
      child: Row(
        children: [
          Icon(icon, size: AppIcon.md, color: AppColors.primary500),
          AppSpace.wGapMd,
          Expanded(
            child: Text(text, style: AppText.body(AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}
