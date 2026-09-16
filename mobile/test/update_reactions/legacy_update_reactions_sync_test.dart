import 'package:blocnet/services/projects/legacy_update_reactions_sync.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'reactions_fixtures.dart';

void main() {
  late FakeReactionsRepository repo;

  setUp(() => repo = FakeReactionsRepository());

  LegacyUpdateReactionsSync newSync() =>
      LegacyUpdateReactionsSync(repository: repo);

  test('sends the old local ids once and clears the local keys', () async {
    SharedPreferences.setMockInitialValues({
      LegacyUpdateReactionsSync.likesKey: ['u1', ' u2 ', 'u1', ''],
      LegacyUpdateReactionsSync.bookmarksKey: ['u3'],
      'unrelated_key': 'kept',
    });

    final sync = newSync();
    expect(await sync.runOnce(), LegacySyncOutcome.imported);
    expect(await sync.runOnce(), LegacySyncOutcome.imported);

    expect(repo.imports, [
      {
        'liked': ['u1', 'u2'],
        'bookmarked': ['u3'],
      },
    ]);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey(LegacyUpdateReactionsSync.likesKey), isFalse);
    expect(prefs.containsKey(LegacyUpdateReactionsSync.bookmarksKey), isFalse);
    expect(prefs.getString('unrelated_key'), 'kept');
  });

  test('a later launch finds nothing and makes no request', () async {
    SharedPreferences.setMockInitialValues({
      LegacyUpdateReactionsSync.likesKey: ['u1'],
    });
    await newSync().runOnce();
    repo.calls.clear();

    // A new process: a fresh sync object over the same storage.
    expect(await newSync().runOnce(), LegacySyncOutcome.nothingToSync);
    expect(repo.calls, isEmpty);
  });

  test('makes no request when there was never anything local', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await newSync().runOnce(), LegacySyncOutcome.nothingToSync);
    expect(repo.calls, isEmpty);
  });

  test('keeps the keys on failure so the next launch retries', () async {
    SharedPreferences.setMockInitialValues({
      LegacyUpdateReactionsSync.likesKey: ['u1'],
    });
    repo.failImport = true;

    final sync = newSync();
    expect(await sync.runOnce(), LegacySyncOutcome.failed);
    // Not retried within the same launch.
    expect(await sync.runOnce(), LegacySyncOutcome.failed);
    expect(repo.calls, ['POST import']);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList(LegacyUpdateReactionsSync.likesKey), ['u1']);

    // Next launch, network back.
    repo.failImport = false;
    expect(await newSync().runOnce(), LegacySyncOutcome.imported);
    expect(prefs.containsKey(LegacyUpdateReactionsSync.likesKey), isFalse);
  });
}
