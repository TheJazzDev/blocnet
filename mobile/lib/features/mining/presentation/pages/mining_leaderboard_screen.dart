import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/mining/data/models/mining_models.dart';
import 'package:blocnet/features/mining/presentation/mine_palette.dart';
import 'package:blocnet/features/mining/presentation/widgets/leaderboard/mine_leaderboard_pager.dart';
import 'package:blocnet/features/mining/presentation/widgets/leaderboard/mine_leaderboard_preview.dart';
import 'package:blocnet/features/mining/presentation/widgets/leaderboard/mine_leaderboard_row.dart';
import 'package:blocnet/features/mining/presentation/widgets/mine_sections.dart';
import 'package:blocnet/features/mining/presentation/widgets/mine_sub_header.dart';
import 'package:blocnet/services/engagement/mining_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// All-time BNP, ten to a page, with the member's own row pinned while it is
/// not on screen.
class MiningLeaderboardScreen extends StatefulWidget {
  const MiningLeaderboardScreen({super.key});

  @override
  State<MiningLeaderboardScreen> createState() =>
      _MiningLeaderboardScreenState();
}

class _MiningLeaderboardScreenState extends State<MiningLeaderboardScreen> {
  final ScrollController _scroll = ScrollController();
  final GlobalKey _listKey = GlobalKey();
  final GlobalKey _meKey = GlobalKey();
  bool _meVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<MiningStore>().loadLeaderboard(force: true);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Whether any part of the member's row is inside the list viewport.
  void _measureMe() {
    if (!mounted) return;
    final list = _listKey.currentContext?.findRenderObject() as RenderBox?;
    final row = _meKey.currentContext?.findRenderObject() as RenderBox?;
    var visible = false;
    if (list != null && row != null && list.hasSize && row.hasSize) {
      final listRect = list.localToGlobal(Offset.zero) & list.size;
      final rowRect = row.localToGlobal(Offset.zero) & row.size;
      visible = listRect.overlaps(rowRect);
    }
    if (visible != _meVisible) setState(() => _meVisible = visible);
  }

  Future<void> _goTo(MiningStore store, int page) async {
    await store.loadLeaderboard(force: true, page: page);
    if (!mounted || !_scroll.hasClients) return;
    _scroll.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<MiningStore>();
    final entries = store.leaderboard;
    final me = store.leaderboardMe;
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureMe());
    final pin = mineShouldPinMe(
      me: me,
      page: entries,
      meRowVisible: _meVisible,
    );

    return Scaffold(
      backgroundColor: MinePalette.ground,
      appBar: const MineSubHeader(title: 'Leaderboard'),
      body: Column(
        children: [
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (_) {
                // Positions settle in the next layout; measure after it.
                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _measureMe());
                return false;
              },
              child: RefreshIndicator(
                onRefresh: () => store.loadLeaderboard(
                  force: true,
                  page: store.leaderboardPage,
                ),
                child: ListView(
                  key: _listKey,
                  controller: _scroll,
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    MineSectionHeader(
                      icon: Icons.leaderboard_outlined,
                      title: 'All-time BNP',
                      trailing:
                          'Page ${store.leaderboardPage} of ${store.leaderboardPageCount}',
                      topPadding: AppSpace.xs,
                    ),
                    ..._rows(store, entries, me),
                    if (entries.isNotEmpty)
                      MineLeaderboardPager(
                        page: store.leaderboardPage,
                        pageCount: store.leaderboardPageCount,
                        onPage: (page) => _goTo(store, page),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (pin && me != null) _PinnedRow(entry: me),
        ],
      ),
    );
  }

  List<Widget> _rows(
    MiningStore store,
    List<MiningLeaderboardEntry> entries,
    MiningLeaderboardEntry? me,
  ) {
    if (entries.isEmpty) {
      final message = store.isLoadingLeaderboard
          ? null
          : store.leaderboardError ?? 'No one has claimed BNP yet.';
      return [
        Padding(
          padding: const EdgeInsets.all(AppSpace.xxl),
          child: Center(
            child: message == null
                ? const CircularProgressIndicator(strokeWidth: 2)
                : Text(message, style: AppText.label(MinePalette.faint)),
          ),
        ),
      ];
    }
    return [
      for (final entry in entries)
        Padding(
          key: entry.userId == me?.userId ? _meKey : null,
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
          child: MineLeaderboardRow(
            entry: entry,
            onTap: () => openMineMemberProfile(context, entry),
          ),
        ),
    ];
  }
}

class _PinnedRow extends StatelessWidget {
  const _PinnedRow({required this.entry});

  final MiningLeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('mine-pinned-row'),
      decoration: const BoxDecoration(
        color: MinePalette.pinGround,
        border: Border(top: BorderSide(color: MinePalette.pinEdge)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
      child: SafeArea(
        top: false,
        child: MineLeaderboardRow(
          entry: entry,
          divided: false,
          nameOverride: 'You',
          onTap: () => openMineMemberProfile(context, entry),
        ),
      ),
    );
  }
}
