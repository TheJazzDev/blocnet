import '../dummy/dummy_admins.dart';
import '../dummy/dummy_posts.dart';
import '../dummy/dummy_projects.dart';
import '../models/admin_model.dart';
import '../models/post_model.dart';
import '../models/priority_model.dart';
import '../models/project_model.dart';

class PostsByProjectIdAndPriorityService {
  static List<Post> fetchPostsByIdAndPriority(
      String projectId, Priority priority) {
    // Fetch the project by projectId
    final project = dummyProjects.firstWhere((proj) => proj.id == projectId);

    // Get the list of postIds from the project
    final postIds = project.postIds;

    // Filter posts by the fetched postIds and the given priority
    final fetchedPosts = dummyPosts.where((post) {
      return postIds.contains(post.postId) && post.priority == priority;
    }).map((post) {
      Project? project;
      Admin? admin;

      // Fetch the associated project
      try {
        project = dummyProjects.firstWhere((proj) => proj.id == post.projectId);
      } catch (e) {
        project = null;
      }

      // Fetch the associated admin for each post
      try {
        admin = dummyAdmins.firstWhere((adm) => adm.id == post.adminId);
      } catch (e) {
        admin = null;
      }

      // Return a new Post object with the admin populated
      return post.copyWith(admin: admin, project: project);
    }).toList();

    return fetchedPosts;
  }
}
