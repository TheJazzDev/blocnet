import 'dart:async';

import 'package:blocnet/features/hunter/data/models/hunter_gem_detail_model.dart';
import 'package:blocnet/features/hunter/data/repositories/hunter_reliability_api_repository.dart';
import 'package:blocnet/features/hunter/presentation/pages/hunter_gem_screen.dart';
import 'package:blocnet/features/projects/data/repositories/project_proposals_api_repository.dart';
import 'package:blocnet/services/api/api_client.dart';
import 'package:blocnet/services/hunter/hunter_board_store.dart';
import 'package:blocnet/shared/widgets/username_suggest_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'hub_fixtures.dart';
import 'hub_harness.dart';

class _NoopHttpClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      throw UnimplementedError();
}

ApiClient _offline() => ApiClient(httpClient: _NoopHttpClient());

/// A store that already holds one gem page, never goes to the network, and
/// records handover calls.
class FakeGemStore extends HunterBoardStore {
  FakeGemStore(this.detail)
      : super(
          repository: HunterReliabilityApiRepository(apiClient: _offline()),
          proposalsRepository:
              ProjectProposalsApiRepository(apiClient: _offline()),
        );

  final HunterGemDetail detail;
  int loads = 0;
  int boardLoads = 0;

  final List<(String, String, String?)> offers = [];
  final List<String> cancels = [];

  /// Set to make the next handover call fail with this message.
  String? failWith;

  /// When set, handover calls wait on it (to observe the busy state).
  Completer<void>? gate;

  bool _busy = false;
  String? _error;

  @override
  HunterGemDetail? gemFor(String projectId) =>
      projectId == detail.gem.projectId ? detail : null;

  @override
  Future<void> loadGem(String projectId) async => loads++;

  @override
  Future<void> loadBoard() async => boardLoads++;

  @override
  bool isHandoverBusy(String projectId) => _busy;

  @override
  String? handoverErrorFor(String projectId) => _error;

  @override
  Future<String?> startHandover(
    String projectId,
    String hunter, {
    String? note,
  }) async {
    offers.add((projectId, hunter, note));
    return await _run() ? 'invite-1' : null;
  }

  @override
  Future<bool> cancelHandover(String projectId) async {
    cancels.add(projectId);
    return _run();
  }

  Future<bool> _run() async {
    _busy = true;
    _error = null;
    notifyListeners();
    await gate?.future;
    _busy = false;
    _error = failWith;
    notifyListeners();
    return failWith == null;
  }
}

/// Pumps the gem page for [detail] at [width] and returns its store.
Future<FakeGemStore> pumpGemPage(
  WidgetTester tester,
  HunterGemDetail detail, {
  double width = 375,
  ProfileSearch? search,
}) async {
  usePhone(tester, width);
  final store = FakeGemStore(detail);
  await tester.pumpWidget(
    ChangeNotifierProvider<HunterBoardStore>.value(
      value: store,
      child: MaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        home: HunterGemScreen(
          initialGem: detail.gem,
          clock: () => hubNow,
          profileSearch: search ?? (_) async => const [],
        ),
      ),
    ),
  );
  await tester.pump();
  return store;
}
