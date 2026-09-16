import 'package:blocnet/features/hunter/data/models/hunter_board_model.dart';
import 'package:blocnet/features/hunter/data/models/hunter_gem_detail_model.dart';
import 'package:blocnet/features/hunter/data/models/hunter_leaderboard_model.dart';
import 'package:blocnet/features/hunter/data/models/hunter_reliability_model.dart';
import 'package:blocnet/features/hunter/data/repositories/hunter_reliability_api_repository.dart';
import 'package:blocnet/features/projects/data/models/project_proposal_model.dart';
import 'package:blocnet/features/projects/data/repositories/project_proposals_api_repository.dart';
import 'package:blocnet/services/api/api_error.dart';
import 'package:flutter/foundation.dart';

/// Hunter reliability state: the signed-in hunter's own board, one gem at a
/// time for the gem page, the hunter's submissions still in review, other
/// hunters' reliability, and the reliability leaderboard.
///
/// A thin client — every number is computed by the backend. Each of the three
/// reads keeps its own loading and error state, so a failed leaderboard never
/// blanks a loaded board. A failed refresh keeps the last good data and sets
/// the error beside it.
class HunterBoardStore extends ChangeNotifier {
  HunterBoardStore({
    HunterReliabilityApiRepository? repository,
    ProjectProposalsApiRepository? proposalsRepository,
  })  : _repository = repository ?? HunterReliabilityApiRepository(),
        _proposalsRepository =
            proposalsRepository ?? ProjectProposalsApiRepository();

  static const int leaderboardPageSize = 20;

  final HunterReliabilityApiRepository _repository;
  final ProjectProposalsApiRepository _proposalsRepository;

  // Board
  HunterBoard? _board;
  bool _isLoadingBoard = false;
  String? _boardError;

  HunterBoard? get board => _board;
  bool get isLoadingBoard => _isLoadingBoard;
  String? get boardError => _boardError;

  // Gem pages
  final Map<String, HunterGemDetail> _gems = {};
  final Set<String> _loadingGems = {};
  final Map<String, String> _gemErrors = {};

  HunterGemDetail? gemFor(String projectId) => _gems[projectId];
  bool isLoadingGem(String projectId) => _loadingGems.contains(projectId);
  String? gemErrorFor(String projectId) => _gemErrors[projectId];

  // Submissions in review
  List<ProjectProposalModel> _pendingProposals = const [];
  bool _hasLoadedProposals = false;

  List<ProjectProposalModel> get pendingProposals => _pendingProposals;
  bool get hasLoadedProposals => _hasLoadedProposals;

  // Reliability by profile
  final Map<String, HunterReliability> _reliability = {};
  final Set<String> _loadingReliability = {};
  final Map<String, String> _reliabilityErrors = {};

  HunterReliability? reliabilityFor(String profileId) =>
      _reliability[profileId];
  bool isLoadingReliability(String profileId) =>
      _loadingReliability.contains(profileId);
  String? reliabilityErrorFor(String profileId) =>
      _reliabilityErrors[profileId];

  // Leaderboard
  List<HunterLeaderboardEntry> _leaderboard = const [];
  String? _leaderboardCursor;
  bool _hasLoadedLeaderboard = false;
  bool _isLoadingLeaderboard = false;
  String? _leaderboardError;

  List<HunterLeaderboardEntry> get leaderboard => _leaderboard;
  bool get hasLoadedLeaderboard => _hasLoadedLeaderboard;
  bool get hasMoreLeaderboard => _leaderboardCursor != null;
  bool get isLoadingLeaderboard => _isLoadingLeaderboard;
  String? get leaderboardError => _leaderboardError;

  Future<void> loadBoard() async {
    if (_isLoadingBoard) return;
    _isLoadingBoard = true;
    _boardError = null;
    notifyListeners();
    try {
      _board = await _repository.fetchBoard();
      // The board carries the hunter's own reliability; keep one copy.
      final own = _board!.reliability;
      if (own.profileId.isNotEmpty) _reliability[own.profileId] = own;
    } catch (error) {
      _boardError = describeApiError(
        error,
        fallback: 'Could not load your gems. Please try again.',
      );
    } finally {
      _isLoadingBoard = false;
      notifyListeners();
    }
  }

  /// Loads one gem for the gem page. A failed refresh keeps the last good
  /// copy beside the error.
  Future<void> loadGem(String projectId) async {
    final id = projectId.trim();
    if (id.isEmpty || _loadingGems.contains(id)) return;
    _loadingGems.add(id);
    _gemErrors.remove(id);
    notifyListeners();
    try {
      _gems[id] = await _repository.fetchGem(id);
    } catch (error) {
      _gemErrors[id] = describeApiError(
        error,
        fallback: 'Could not load this gem. Please try again.',
      );
    } finally {
      _loadingGems.remove(id);
      notifyListeners();
    }
  }

  /// `GET /project-proposals/mine?status=pending`. A failure leaves the last
  /// list in place: a review card is a courtesy, not the board.
  Future<void> loadPendingProposals() async {
    try {
      final proposals = await _proposalsRepository.listMine(status: 'pending');
      _pendingProposals =
          proposals.where((p) => p.isPending).toList(growable: false);
      _hasLoadedProposals = true;
      notifyListeners();
    } catch (_) {
      // Keep what we had.
    }
  }

  Future<void> loadReliability(String profileId) async {
    final id = profileId.trim();
    if (id.isEmpty || _loadingReliability.contains(id)) return;
    _loadingReliability.add(id);
    _reliabilityErrors.remove(id);
    notifyListeners();
    try {
      _reliability[id] = await _repository.fetchReliability(id);
    } catch (error) {
      _reliabilityErrors[id] = describeApiError(
        error,
        fallback: 'Could not load this hunter’s reliability.',
      );
    } finally {
      _loadingReliability.remove(id);
      notifyListeners();
    }
  }

  /// Loads the first page, or with [loadMore] the next one.
  Future<void> loadLeaderboard({bool loadMore = false}) async {
    if (_isLoadingLeaderboard) return;
    if (loadMore && _leaderboardCursor == null) return;
    _isLoadingLeaderboard = true;
    _leaderboardError = null;
    notifyListeners();
    try {
      final page = await _repository.fetchLeaderboard(
        limit: leaderboardPageSize,
        cursor: loadMore ? _leaderboardCursor : null,
      );
      _leaderboard =
          loadMore ? [..._leaderboard, ...page.entries] : page.entries;
      _leaderboardCursor = page.nextCursor;
      _hasLoadedLeaderboard = true;
    } catch (error) {
      _leaderboardError = describeApiError(
        error,
        fallback: 'Could not load the hunter ranking.',
      );
    } finally {
      _isLoadingLeaderboard = false;
      notifyListeners();
    }
  }

  /// Drops everything, e.g. on sign-out.
  void clear() {
    _board = null;
    _boardError = null;
    _gems.clear();
    _gemErrors.clear();
    _pendingProposals = const [];
    _hasLoadedProposals = false;
    _reliability.clear();
    _reliabilityErrors.clear();
    _leaderboard = const [];
    _leaderboardCursor = null;
    _hasLoadedLeaderboard = false;
    _leaderboardError = null;
    notifyListeners();
  }
}
