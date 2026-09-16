/// Fakes and a provider host for Mine widget tests.
library;

import 'package:blocnet/features/mining/data/mine_local_cache.dart';
import 'package:blocnet/features/mining/data/models/mining_claim_models.dart';
import 'package:blocnet/features/mining/data/models/mining_models.dart';
import 'package:blocnet/features/mining/data/repositories/mining_api_repository.dart';
import 'package:blocnet/features/notifications/data/models/notification_preferences_model.dart';
import 'package:blocnet/features/notifications/data/repositories/notifications_api_repository.dart';
import 'package:blocnet/services/api/api_client.dart';
import 'package:blocnet/services/auth/auth_store.dart';
import 'package:blocnet/services/engagement/mining_store.dart';
import 'package:blocnet/services/notifications/notification_settings_store.dart';
import 'package:blocnet/services/wallet/wallet_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class FakeMineRepo extends MiningApiRepository {
  FakeMineRepo(this.snapshotBody);

  Map<String, dynamic>? snapshotBody;
  bool failSnapshot = false;
  int snapshotCalls = 0;
  Map<String, dynamic>? claimBody;
  Map<String, dynamic>? referralBody;
  List<Map<String, dynamic>> downline = const [];
  List<Map<String, dynamic>> leaderboardRows = const [];
  Map<String, dynamic>? leaderboardMe;
  int leaderboardTotal = 0;
  final List<int> leaderboardOffsets = [];

  @override
  Future<MiningSnapshot?> fetchMiningSnapshot() async {
    snapshotCalls++;
    if (failSnapshot) throw ApiException('Network is unreachable');
    final body = snapshotBody;
    return body == null ? null : MiningSnapshot.fromApi(body);
  }

  @override
  Future<MiningClaimResult> claimMining() async =>
      MiningClaimResult.fromApi(claimBody ?? const {});

  @override
  Future<ReferralSummaryModel?> fetchReferralSummary() async {
    final body = referralBody;
    return body == null ? null : ReferralSummaryModel.fromApi(body);
  }

  @override
  Future<DownlineResponse?> fetchDownline({
    int limit = 20,
    int offset = 0,
  }) async =>
      DownlineResponse.fromApi({'data': downline, 'total': downline.length});

  @override
  Future<MiningLeaderboardResponse?> fetchLeaderboard({
    int limit = 20,
    int offset = 0,
  }) async {
    leaderboardOffsets.add(offset);
    final page = leaderboardRows.skip(offset).take(limit).toList();
    return MiningLeaderboardResponse.fromApi({
      'data': page,
      'total':
          leaderboardTotal == 0 ? leaderboardRows.length : leaderboardTotal,
      'limit': limit,
      'offset': offset,
      'me': leaderboardMe,
    });
  }
}

class FakeNotificationsRepo extends NotificationsApiRepository {
  FakeNotificationsRepo({
    this.masterEnabled = true,
    this.overrides = const {},
    this.categoryEnabled = true,
  });

  final bool masterEnabled;
  final Map<String, bool> overrides;
  final bool categoryEnabled;
  final List<Map<String, dynamic>?> patches = [];

  Map<String, dynamic> _prefs(Map<String, bool> typeOverrides) => {
        'masterEnabled': masterEnabled,
        'categories': {'mining_referrals': categoryEnabled},
        'typeOverrides': typeOverrides,
        'criticalTypes': <String>[],
      };

  @override
  Future<NotificationPreferencesCatalog> fetchPreferenceCatalog() async =>
      NotificationPreferencesCatalog.fromApi({
        'categories': [
          {
            'key': 'mining_referrals',
            'label': 'Mining',
            'types': ['mining_claimed', 'mining_cycle_ready'],
          },
        ],
        'criticalTypes': <String>[],
      });

  @override
  Future<NotificationPreferences?> fetchPreferences() async =>
      NotificationPreferences.fromApi(_prefs(overrides));

  @override
  Future<NotificationPreferences?> updatePreferences({
    Map<String, dynamic>? body,
  }) async {
    patches.add(body);
    final next = Map<String, bool>.from(overrides);
    for (final item in (body?['typeOverrides'] as List? ?? const [])) {
      next[item['type'] as String] = item['enabled'] as bool;
    }
    return NotificationPreferences.fromApi(_prefs(next));
  }
}

/// In-memory stand-in for the device cache.
class MemoryMineCache extends MineLocalCache {
  MemoryMineCache({this.balance, this.seenExplainer = true});

  int? balance;
  bool seenExplainer;
  final Set<String> dismissed = {};

  @override
  Future<int?> readBalance() async => balance;
  @override
  Future<void> writeBalance(int value) async => balance = value;
  @override
  Future<void> clearBalance() async => balance = null;
  @override
  Future<bool> hasSeenExplainer() async => seenExplainer;
  @override
  Future<void> markExplainerSeen() async => seenExplainer = true;
  @override
  Future<Set<String>> dismissedExpiredCycles() async => {...dismissed};
  @override
  Future<void> dismissExpiredCycle(String sessionId) async =>
      dismissed.add(sessionId);
}

class TestAuthStore extends AuthStore {
  TestAuthStore()
      : super(
          enableSupabaseAuthListener: false,
          supabaseConfiguredOverride: false,
        );
}

MiningStore mineStore(
  FakeMineRepo repo, {
  DateTime? now,
  MemoryMineCache? cache,
}) {
  final fixed = now;
  return MiningStore(
    repository: repo,
    localCache: cache ?? MemoryMineCache(),
    deviceClock: fixed == null ? null : () => fixed,
  );
}

/// Loaded notification settings, ready for the notify switch.
Future<NotificationSettingsStore> loadedSettings(
  FakeNotificationsRepo repo,
) async {
  final store = NotificationSettingsStore(repository: repo);
  await store.refresh();
  return store;
}

Widget mineHost({
  required MiningStore store,
  required NotificationSettingsStore settings,
  required Widget child,
  PreferredSizeWidget? appBar,
  Map<String, WidgetBuilder> routes = const {},
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<MiningStore>.value(value: store),
      ChangeNotifierProvider<NotificationSettingsStore>.value(value: settings),
      ChangeNotifierProvider<AuthStore>(create: (_) => TestAuthStore()),
      ChangeNotifierProvider<WalletStore>(create: (_) => WalletStore()),
    ],
    child: MaterialApp(
      routes: routes,
      home: Scaffold(appBar: appBar, body: child),
    ),
  );
}

/// Phone-sized surface (390 wide) that is tall enough to lay out the whole
/// tab without scrolling.
void usePhone(WidgetTester tester, {double height = 2400}) {
  tester.view.physicalSize = Size(390, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Asserts each finder sits strictly below the previous one.
void expectTopToBottom(WidgetTester tester, List<Finder> finders) {
  double? last;
  for (final finder in finders) {
    expect(finder, findsOneWidget, reason: '$finder');
    final y = tester.getTopLeft(finder).dy;
    if (last != null) {
      expect(y, greaterThan(last), reason: '$finder should follow');
    }
    last = y;
  }
}
