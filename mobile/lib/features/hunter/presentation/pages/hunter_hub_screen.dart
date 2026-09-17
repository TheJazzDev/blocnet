import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/hunter/data/models/hunter_board_model.dart';
import 'package:blocnet/features/hunter/data/models/project_invite_model.dart';
import 'package:blocnet/features/hunter/presentation/hub_navigation.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/board/hub_identity_row.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/hub_app_bar_actions.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/hub_board_view.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/hub_fab_host.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_styles.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/hunter/hunter_board_store.dart';
import 'package:blocnet/services/projects/project_invites_store.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The Hunter Hub: which of my gems need me right now, and who is waiting.
///
/// Embedded as tab 3 of the hunter space, where the shell supplies the app
/// bar and FAB; pushed standalone at `/hunter-hub` (e.g. from a
/// notification), where it supplies its own.
class HunterHubScreen extends StatefulWidget {
  const HunterHubScreen({super.key, this.clock});

  /// Injectable "now" for tests.
  final DateTime Function()? clock;

  @override
  State<HunterHubScreen> createState() => _HunterHubScreenState();
}

class _HunterHubScreenState extends State<HunterHubScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load(force: false);
    });
  }

  Future<void> _load({required bool force}) async {
    final board = context.read<HunterBoardStore>();
    final invites = context.read<ProjectInvitesStore>();
    await Future.wait([
      board.loadBoard(),
      invites.loadMine(force: force),
      board.loadPendingProposals(),
    ]);
  }

  Future<void> _respond(ProjectInviteModel invite, bool accept) async {
    final invites = context.read<ProjectInvitesStore>();
    final board = context.read<HunterBoardStore>();
    final messenger = ScaffoldMessenger.maybeOf(context);
    final ok = await invites.respond(invite.id, accept: accept);
    if (!ok) {
      messenger?.showSnackBar(SnackBar(
        content: Text(invites.lastError ?? 'Could not answer the invite.'),
      ));
      return;
    }
    if (accept) await board.loadBoard();
  }

  HubIdentity _identity(AuthStore auth, HunterBoard board) {
    final r = board.reliability;
    return HubIdentity(
      name: r.displayName ?? auth.displayName ?? r.username ?? 'Hunter',
      handle: r.username ?? auth.username,
      avatarUrl: r.avatarUrl ?? auth.avatarUrl,
      level: r.level?.level,
      levelName: r.level?.name,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();
    final store = context.watch<HunterBoardStore>();
    final invites = context.watch<ProjectInvitesStore>();
    final board = store.board;
    final isStandalone = Navigator.of(context).canPop();

    final Widget body;
    if (board == null) {
      body = _BoardStatus(
        error: store.isLoadingBoard ? null : store.boardError,
        onRetry: () => _load(force: true),
      );
    } else {
      body = HubBoardView(
        board: board,
        identity: _identity(auth, board),
        invites: invites.pendingInvites,
        proposals: store.pendingProposals,
        now: (widget.clock ?? DateTime.now)(),
        onRefresh: () => _load(force: true),
        actions: HubBoardActions(
          onOpenGem: (gem) => HubNavigation.openGem(context, gem),
          onPostUpdate: (gem) =>
              HubNavigation.openComposer(context, projectId: gem.projectId),
          onSubmitGem: () => HubNavigation.openSubmit(context),
          onRespondToInvite: _respond,
          isResponding: invites.isResponding,
        ),
      );
    }

    if (!isStandalone) return body;
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: const CustomAppBar(
        title: 'Hub',
        backButton: true,
        showSearch: false,
        showFilter: false,
        showSpaceSwitcher: false,
        actions: [HubHistoryAction()],
      ),
      body: body,
      floatingActionButton: const HubFabHost(),
    );
  }
}

class _BoardStatus extends StatelessWidget {
  const _BoardStatus({required this.error, required this.onRetry});

  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (error == null) {
      return Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: HubTone.accent,
          ),
        ),
      );
    }
    return Center(
      child: Padding(
        padding: AppSpace.allXl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              error!,
              textAlign: TextAlign.center,
              style: HubType.body(AppColors.textMuted),
            ),
            AppSpace.gapMd,
            AppButton(
              label: 'Try again',
              variant: AppButtonVariant.outline,
              onPressed: onRetry,
              size: AppButtonSize.compact,
            ),
          ],
        ),
      ),
    );
  }
}
