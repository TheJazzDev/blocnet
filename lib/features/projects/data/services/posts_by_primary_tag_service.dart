import '../dummy/dummy_admins.dart';
import '../dummy/dummy_posts.dart';
import '../dummy/dummy_projects.dart';
import '../models/admin_model.dart';
import '../models/post_model.dart';
import '../models/primary_tag_model.dart';
import '../models/project_model.dart';

class PostsByPrimaryTagService {
  static List<Post> fetchPostsByPrimaryTag(PrimaryTag primaryTag) {
    // Step 1: Search through all dummyProjects and check their primaryTag
    final matchingProjectPostIds = dummyProjects
        .where((project) => project.primaryTag == primaryTag)
        .map((project) => project.postIds)
        .toList();

    // Step 2: Merge all the lists into one list
    final mergedPostIds = matchingProjectPostIds.expand((ids) => ids).toList();

    // Step 3: Using the postIds in the list, fetch all related dummyPosts
    final fetchedPosts = dummyPosts
        .where((post) => mergedPostIds.contains(post.postId))
        .map((post) {
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
