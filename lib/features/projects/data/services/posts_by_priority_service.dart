import '../dummy/dummy_admins.dart';
import '../dummy/dummy_posts.dart';
import '../dummy/dummy_projects.dart';
import '../models/admin_model.dart';
import '../models/post_model.dart';
import '../models/priority_model.dart';
import '../models/project_model.dart';

class PostsByPriorityService {
  static List<Post> fetchPostsByPriority(Priority priority) {
    // Search through all dummyPosts and check their primaryTag
    final fetchedPosts =
        dummyPosts.where((post) => post.priority == priority).map((post) {
      Project? project;
      Admin? admin;

      // Fetch the associated project
      try {
        project = dummyProjects.firstWhere((proj) => proj.id == post.projectId);
      } catch (e) {
        project = null;
      }

      // Fetch the associated admin
      try {
        admin = dummyAdmins.firstWhere((adm) => adm.id == post.adminId);
      } catch (e) {
        admin = null;
      }

      // Return a new Post object with the project and admin populated
      return post.copyWith(project: project, admin: admin);
    }).toList();

    return fetchedPosts;
  }
}
