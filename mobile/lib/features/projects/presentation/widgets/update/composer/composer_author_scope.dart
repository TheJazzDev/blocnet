import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/services/auth/auth_store.dart';

/// Which gems an author may post to, as the composer lists them. The
/// backend still decides; this only keeps the picker to gems that will not
/// be refused.
class ComposerAuthorScope {
  const ComposerAuthorScope._();

  /// A hunter (or anyone in Hunter space) posts only to gems they keep.
  static bool isHunterRestricted(AuthStore auth) {
    return auth.isInHunterSpace ||
        (auth.isHunter && !auth.isOwner && !auth.isAdmin);
  }

  static List<Project> projectsFor({
    required AuthStore auth,
    required List<Project> projects,
  }) {
    if (!isHunterRestricted(auth)) return projects;

    final userId = auth.userId?.trim() ?? '';
    final username = _identity(auth.username ?? auth.displayName ?? '');

    return projects.where((project) {
      if (userId.isNotEmpty &&
          (project.adminId == userId || project.admin?.id == userId)) {
        return true;
      }
      final projectUsername =
          _identity(project.admin?.username ?? project.admin?.name ?? '');
      return username.isNotEmpty && projectUsername == username;
    }).toList(growable: false);
  }

  static String _identity(String value) =>
      value.replaceAll('@', '').trim().toLowerCase();
}
