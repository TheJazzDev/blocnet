import 'package:blocnet/features/hunter/data/models/hunter_reliability_model.dart';
import 'package:blocnet/features/hunter/data/repositories/hunter_reliability_api_repository.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/features/projects/data/repositories/projects_api_repository.dart';
import 'package:blocnet/features/projects/data/repositories/updates_api_repository.dart';

/// The three reads behind the gem page. Injectable for tests.
class GemPageSources {
  GemPageSources({
    Future<Project?> Function(String projectId)? project,
    Future<List<Update>> Function(String projectId)? updates,
    Future<HunterReliability> Function(String profileId)? keeper,
  })  : _project = project,
        _updates = updates,
        _keeper = keeper;

  final Future<Project?> Function(String projectId)? _project;
  final Future<List<Update>> Function(String projectId)? _updates;
  final Future<HunterReliability> Function(String profileId)? _keeper;

  /// The server's page of updates per gem.
  static const int updatesLimit = 100;

  /// `GET /projects/:id`.
  Future<Project?> project(String projectId) =>
      (_project ?? ProjectsApiRepository().fetchProjectById)(projectId);

  /// `GET /updates?projectId=`, newest first.
  Future<List<Update>> updates(String projectId) {
    final read = _updates;
    if (read != null) return read(projectId);
    return UpdatesApiRepository().fetchUpdates(
      projectId: projectId,
      limit: updatesLimit,
    );
  }

  /// `GET /hunters/:id/reliability`.
  Future<HunterReliability> keeper(String profileId) =>
      (_keeper ?? HunterReliabilityApiRepository().fetchReliability)(
        profileId,
      );
}
