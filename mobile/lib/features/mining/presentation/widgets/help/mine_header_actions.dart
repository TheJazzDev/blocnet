import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/features/mining/presentation/mine_palette.dart';
import 'package:blocnet/features/mining/presentation/widgets/help/mine_explainer.dart';
import 'package:blocnet/features/mining/presentation/widgets/help/mine_help_popover.dart';
import 'package:blocnet/services/engagement/mining_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The Mine tab's app bar actions: `history` and `help` (the popover).
class MineHeaderActions extends StatelessWidget {
  const MineHeaderActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _HeaderIcon(
          key: const ValueKey('mine-history'),
          icon: Icons.history_rounded,
          label: 'Hourly history',
          onTap: () =>
              Navigator.of(context).pushNamed(AppRoutes.miningHourlyHistory),
        ),
        const MineHelpAction(),
      ],
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox.square(
          dimension: 44,
          child: Center(
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? MinePalette.chip : Colors.transparent,
              ),
              child: Icon(
                icon,
                size: AppIcon.md,
                color: active ? MinePalette.white : MinePalette.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The `?` that owns the "How mining works" popover.
class MineHelpAction extends StatefulWidget {
  const MineHelpAction({super.key});

  @override
  State<MineHelpAction> createState() => _MineHelpActionState();
}

class _MineHelpActionState extends State<MineHelpAction> {
  final MineExplainer _explainer = MineExplainer.instance;
  OverlayEntry? _entry;

  @override
  void initState() {
    super.initState();
    _explainer.addListener(_sync);
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  @override
  void dispose() {
    _explainer.removeListener(_sync);
    _removeEntry();
    // Leaving the tab closes the popover; it must not float over another.
    _explainer.close();
    super.dispose();
  }

  void _sync() {
    if (!mounted) return;
    setState(() {});
    if (_explainer.isOpen && _entry == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _insert());
    } else if (!_explainer.isOpen) {
      _removeEntry();
    }
  }

  void _insert() {
    if (!mounted || !_explainer.isOpen || _entry != null) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final origin = box.localToGlobal(Offset.zero);
    final anchor = origin & box.size;
    final scaffold = Scaffold.maybeOf(context);
    final scrimTop = scaffold?.appBarMaxHeight ?? anchor.bottom;
    final config = context.read<MiningStore>().snapshot?.config;

    _entry = OverlayEntry(
      builder: (_) => MineHelpOverlay(
        anchor: anchor.deflate(7),
        scrimTop: scrimTop,
        cycleHours: config?.cycleHours ?? 24,
        claimWindowHours: config?.claimWindowHours ?? 48,
        onClose: _explainer.close,
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(_entry!);
  }

  void _removeEntry() {
    _entry?.remove();
    _entry?.dispose();
    _entry = null;
  }

  @override
  Widget build(BuildContext context) {
    return _HeaderIcon(
      key: const ValueKey('mine-help'),
      icon: Icons.help_outline_rounded,
      label: 'How mining works',
      active: _explainer.isOpen,
      onTap: _explainer.toggle,
    );
  }
}
