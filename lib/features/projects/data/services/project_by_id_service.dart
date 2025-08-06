import '../dummy/dummy_admins.dart';
import '../dummy/dummy_posts.dart';
import '../dummy/dummy_projects.dart';
import '../models/admin_model.dart';
import '../models/post_model.dart';
import '../models/project_model.dart';

class ProjectByIdService {
  static Project fetchProjectById(String projectId) {
    // Search through all dummyProjects and check their id
    final fetchedProject =
        dummyProjects.firstWhere((project) => project.id == projectId);

    // Fetch the associated posts
    List<Post>? posts;
    try {
      posts = dummyPosts
          .where((post) => fetchedProject.postIds.contains(post.id))
          .toList();
    } catch (e) {
      posts = null;
    }

    // Fetch the associated admin
    Admin? admin;
    try {
      admin = dummyAdmins.firstWhere((adm) => adm.id == fetchedProject.adminId);
    } catch (e) {
      admin = null;
    }

    // Return a new Project object with posts and admin populated
    return fetchedProject.copyWith(posts: posts, admin: admin);
  }
}
