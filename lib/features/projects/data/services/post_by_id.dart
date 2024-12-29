import '../dummy/dummy_admins.dart';
import '../dummy/dummy_posts.dart';
import '../dummy/dummy_projects.dart';
import '../models/admin_model.dart';
import '../models/post_model.dart';
import '../models/project_model.dart';

class PostById {
  static Post fetchPostById(String postId) {
    // Search through all dummyPosts and check their primaryTag
    final fetchedPost = dummyPosts.firstWhere((post) => post.postId == postId);
    Project? project;
    Admin? admin;

    // Fetch the associated project
    try {
      project =
          dummyProjects.firstWhere((proj) => proj.id == fetchedPost.projectId);
    } catch (e) {
      project = null;
    }

    // Fetch the associated admin
    try {
      admin = dummyAdmins.firstWhere((adm) => adm.id == fetchedPost.adminId);
    } catch (e) {
      admin = null;
    }

    // Return a new Post object with the project and admin populated
    return fetchedPost.copyWith(project: project, admin: admin);
  }
}
