part of '../home.dart';

/// Edge Engine interactions reachable from the Home teaser card.
mixin _HomeEdgeActions on State<HomeScreen> {
  Future<void> _sendEdgeFeedback(
    EdgeBriefDecision decision,
    String action,
  ) async {
    final edgeStore = context.read<EdgeEngineStore>();
    final ok = await edgeStore.sendFeedback(
      decisionId: decision.decisionId,
      action: action,
      context: const {
        'surface': 'home_edge_brief',
      },
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'BEE feedback saved: ${action.toUpperCase()}'
              : 'Failed to submit BEE feedback',
        ),
      ),
    );
  }

  Future<void> _openEdgeExplain(EdgeBriefDecision decision) async {
    final edgeStore = context.read<EdgeEngineStore>();
    final explain = await edgeStore.fetchExplain(decision.decisionId);
    if (!mounted) return;

    if (explain == null || !explain.hasExplanation) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load BEE explanation')),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
      builder: (_) => EdgeExplainSheet(explain: explain),
    );
  }

  Future<void> _openEdgeEnginePage() async {
    final edgeStore = context.read<EdgeEngineStore>();
    if (edgeStore.brief == null && !edgeStore.isFetching) {
      await edgeStore.refresh();
    }
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (pageContext) => EdgeEnginePage(
          onAction: _sendEdgeFeedback,
          onExplain: _openEdgeExplain,
          onFollowProjects: () {
            Navigator.of(pageContext).pop();
            if (!mounted) return;
            MainTabScope.maybeOf(context)
                ?.selectTab(MainTabScope.discoverTab);
          },
        ),
      ),
    );
  }
}
