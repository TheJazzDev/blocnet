import 'package:blocnet/features/mining/data/models/mining_models.dart';
import 'package:blocnet/features/mining/data/repositories/mining_api_repository.dart';
import 'package:blocnet/services/engagement/mining_store.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeMiningRepository extends MiningApiRepository {
  _FakeMiningRepository({this.summary, this.error});

  final ReferralSummaryModel? summary;
  final Object? error;
  int calls = 0;

  @override
  Future<ReferralSummaryModel?> fetchReferralSummary() async {
    calls++;
    if (error != null) throw error!;
    return summary;
  }
}

void main() {
  group('MiningStore.loadReferralSummary', () {
    test('exposes totals from /referrals/me and clears loading', () async {
      final repo = _FakeMiningRepository(
        summary: ReferralSummaryModel.fromApi({
          'code': 'ABCD1234',
          'referredBy': null,
          'canBindUntil': '2026-02-22T00:00:00.000Z',
          'bindWindowOpen': true,
          'totalDirectReferrals': 7,
          'activeDirectReferrals': 3,
        }),
      );
      final store = MiningStore(repository: repo);

      expect(store.referralSummary, isNull);

      final future = store.loadReferralSummary();
      expect(store.isLoadingReferral, isTrue);
      await future;

      expect(store.isLoadingReferral, isFalse);
      expect(store.referralError, isNull);
      expect(store.referralSummary?.totalDirectReferrals, 7);
      expect(store.referralSummary?.activeDirectReferrals, 3);
    });

    test('does not refetch when cached unless forced', () async {
      final repo = _FakeMiningRepository(
        summary: ReferralSummaryModel.fromApi({'totalDirectReferrals': 1}),
      );
      final store = MiningStore(repository: repo);

      await store.loadReferralSummary();
      await store.loadReferralSummary();
      expect(repo.calls, 1);

      await store.loadReferralSummary(force: true);
      expect(repo.calls, 2);
    });

    test('records a referral error and leaves the summary empty', () async {
      final repo = _FakeMiningRepository(error: StateError('boom'));
      final store = MiningStore(repository: repo);

      await store.loadReferralSummary();

      expect(store.isLoadingReferral, isFalse);
      expect(store.referralSummary, isNull);
      expect(store.referralError, isNotNull);
      expect(store.referralError, contains('boom'));
    });
  });
}
