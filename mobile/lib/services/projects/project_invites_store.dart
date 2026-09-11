import 'package:blocnet/features/hunter/data/models/project_invite_model.dart';
import 'package:blocnet/features/hunter/data/repositories/project_invites_api_repository.dart';
import 'package:blocnet/services/api/api_error.dart';
import 'package:flutter/foundation.dart';

/// The current hunter's project invites (`/project-invites/mine`).
class ProjectInvitesStore extends ChangeNotifier {
  ProjectInvitesStore({ProjectInvitesApiRepository? repository})
      : _repository = repository ?? ProjectInvitesApiRepository();

  final ProjectInvitesApiRepository _repository;

  List<ProjectInviteModel> _invites = const [];
  final Set<String> _respondingIds = <String>{};
  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _lastError;

  List<ProjectInviteModel> get invites => List.unmodifiable(_invites);
  List<ProjectInviteModel> get pendingInvites =>
      _invites.where((invite) => invite.isPending).toList(growable: false);
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  String? get lastError => _lastError;
  bool isResponding(String inviteId) => _respondingIds.contains(inviteId);

  Future<void> loadMine({bool force = false}) async {
    if (_isLoading) return;
    if (!force && _hasLoaded) return;

    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      _invites = await _repository.listMine(limit: 50);
      _hasLoaded = true;
    } catch (error) {
      _lastError = describeApiError(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Accepts or declines one invite. Returns true on success; the invite
  /// is updated in place so the UI can drop it from the pending list.
  Future<bool> respond(String inviteId, {required bool accept}) async {
    if (_respondingIds.contains(inviteId)) return false;

    _respondingIds.add(inviteId);
    _lastError = null;
    notifyListeners();

    try {
      final updated =
          await _repository.respond(inviteId: inviteId, accept: accept);
      _invites = _invites
          .map((invite) => invite.id == inviteId
              ? (updated ??
                  invite.copyWith(
                    status: accept ? 'accepted' : 'rejected',
                    reviewedAt: DateTime.now(),
                  ))
              : invite)
          .toList(growable: false);
      return true;
    } catch (error) {
      _lastError = describeApiError(error);
      return false;
    } finally {
      _respondingIds.remove(inviteId);
      notifyListeners();
    }
  }

  void clear() {
    _invites = const [];
    _hasLoaded = false;
    _lastError = null;
    notifyListeners();
  }
}
