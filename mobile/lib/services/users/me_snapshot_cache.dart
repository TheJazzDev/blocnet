import 'package:blocnet/services/api/api_client.dart';

/// Process-wide, short-lived snapshot of the `GET /me` document.
///
/// `/me` returns one large document and three unrelated consumers each want a
/// small slice of it: [AuthStore] (profile fields, roles, wallet/KYC status),
/// `ProjectsStore` (followed project ids + follow preferences) and
/// `UserProfileStore` (following count). On a cold start they fired seconds
/// apart, so the request went out twice — `ApiClient` only collapses GETs that
/// are still *in flight*.
///
/// Every consumer now reads through this cache, so one request serves all of
/// them. `GET /me/home-bootstrap` returns the same document under `meSummary`
/// (the handler literally calls `UsersService.getMe`), so that response is
/// written through here too and can satisfy the readers on its own.
///
/// Staleness is the only real risk, so the rules are deliberately blunt:
/// * the TTL is short — long enough to cover a boot, short enough that a
///   missed invalidation self-heals within a screen;
/// * every mutation that touches the `/me` document calls [invalidate];
/// * anything that must be current (pull-to-refresh) passes `forceRefresh`;
/// * signing out or switching user calls [reset], so one account never reads
///   another's snapshot.
///
/// Mirrors the static-cache shape already used by `ProjectFollowsStore` and
/// `UpdateLikesStore`.
class MeSnapshotCache {
  MeSnapshotCache._();

  /// Covers a cold start (the boot reads land several seconds apart) without
  /// letting a missed invalidation linger.
  static const Duration ttl = Duration(seconds: 30);

  static Map<String, dynamic>? _snapshot;
  static DateTime? _storedAt;
  static Future<Map<String, dynamic>?>? _inFlight;

  /// The snapshot if it is still inside [ttl], otherwise null.
  static Map<String, dynamic>? get fresh {
    final snapshot = _snapshot;
    final storedAt = _storedAt;
    if (snapshot == null || storedAt == null) return null;
    if (DateTime.now().difference(storedAt) > ttl) return null;
    return snapshot;
  }

  static bool get hasFresh => fresh != null;

  /// Reads through the cache, calling [fetch] only on a miss.
  ///
  /// Concurrent callers that miss share the same request. [forceRefresh]
  /// bypasses the stored snapshot but still publishes its result.
  static Future<Map<String, dynamic>?> read({
    required Future<Map<String, dynamic>?> Function() fetch,
    bool forceRefresh = false,
  }) {
    if (!forceRefresh) {
      final cached = fresh;
      if (cached != null) return Future<Map<String, dynamic>?>.value(cached);
      final pending = _inFlight;
      if (pending != null) return pending;
    }

    final request = fetch().then((value) {
      if (value != null) write(value);
      return value;
    });
    _inFlight = request;
    request.whenComplete(() {
      if (identical(_inFlight, request)) _inFlight = null;
    }).ignore();
    return request;
  }

  /// Convenience read-through for the canonical `GET /me` request. Keeping the
  /// path in one place means no consumer talks to `/me` directly.
  static Future<Map<String, dynamic>?> readThrough(
    ApiClient apiClient, {
    bool forceRefresh = false,
  }) {
    return read(
      forceRefresh: forceRefresh,
      fetch: () async {
        final response = await apiClient.get('/me');
        return response is Map<String, dynamic> ? response : null;
      },
    );
  }

  /// Publishes a snapshot without a request. Used by the home bootstrap, whose
  /// `meSummary` is the same document.
  static void write(Map<String, dynamic>? snapshot) {
    if (snapshot == null) return;
    _snapshot = snapshot;
    _storedAt = DateTime.now();
  }

  /// Drops the snapshot after a mutation that changes the `/me` document.
  /// An in-flight request is left alone: it was issued against the new state
  /// or will be superseded by the next read.
  static void invalidate() {
    _snapshot = null;
    _storedAt = null;
  }

  /// Drops everything, in-flight request included. Used on sign-out and on
  /// user switch, where reusing the previous account's document would be a
  /// correctness bug rather than just staleness.
  static void reset() {
    invalidate();
    _inFlight = null;
  }

  /// Keeps the snapshot only when it belongs to [userId].
  static void retainForUser(String? userId) {
    final snapshot = _snapshot;
    if (snapshot == null) return;
    final owner = snapshot['id']?.toString();
    if (owner == null || owner.isEmpty) return;
    if (userId == null || userId.isEmpty || owner != userId) {
      reset();
    }
  }
}
