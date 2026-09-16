import 'package:blocnet/features/hunter/data/models/hunter_board_model.dart';
import 'package:blocnet/features/hunter/domain/hub_layout.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/board/gem_attention_row.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/board/gem_current_row.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/board/gem_fold_line.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_section_header.dart';
import 'package:flutter/material.dart';

/// `YOUR GEMS`, most in need first, then the current gems — listed, under
/// their own header, or folded behind one line (D3).
class HubGemList extends StatefulWidget {
  const HubGemList({
    super.key,
    required this.layout,
    required this.onOpenGem,
    required this.onPostUpdate,
  });

  final HubLayout layout;
  final ValueChanged<HunterBoardGem> onOpenGem;
  final ValueChanged<HunterBoardGem> onPostUpdate;

  @override
  State<HubGemList> createState() => _HubGemListState();
}

class _HubGemListState extends State<HubGemList> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final layout = widget.layout;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HubSectionHeader(
          key: const ValueKey('hub-section-gems'),
          label: 'Your gems',
          icon: Icons.layers_outlined,
          trailing: layout.gemsTrailing,
        ),
        for (final gem in layout.attention)
          GemAttentionRow(
            key: ValueKey('hub-row-${gem.projectId}'),
            gem: gem,
            now: layout.now,
            compact: layout.compactCopy,
            onOpen: () => widget.onOpenGem(gem),
            onPost: () => widget.onPostUpdate(gem),
          ),
        if (layout.listsCurrentUnderHeader)
          HubSectionHeader(
            key: const ValueKey('hub-section-current'),
            label: 'Current',
            trailing: layout.current.length == 1
                ? '1 gem'
                : '${layout.current.length} gems',
          ),
        if (layout.foldsCurrent)
          GemFoldLine(
            key: const ValueKey('hub-fold'),
            label: layout.foldLabel,
            expanded: _expanded,
            onToggle: () => setState(() => _expanded = !_expanded),
          ),
        if (!layout.foldsCurrent || _expanded)
          for (final gem in layout.current)
            GemCurrentRow(
              key: ValueKey('hub-row-${gem.projectId}'),
              gem: gem,
              now: layout.now,
              onOpen: () => widget.onOpenGem(gem),
            ),
      ],
    );
  }
}
