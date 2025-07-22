// import '../dummy/dummy_admins.dart';
// import '../dummy/dummy_posts.dart';
// import '../dummy/dummy_projects.dart';
// import '../models/admin_model.dart';
// import '../models/post_model.dart';
// import '../models/project_model.dart';

// class AllPostsService {
//   // Enrich posts with project and admin details
//   static List<Post> getAllPosts() {
//     return dummyPosts.map((post) {
//       Admin? admin;
//       Project? project;

//       try {
//         project = dummyProjects.firstWhere((p) => p.id == post.projectId);
//       } catch (e) {
//         project = null;
//       }

//       try {
//         admin = dummyAdmins.firstWhere((a) => a.id == post.adminId);
//       } catch (e) {
//         admin = null;
//       }

//       return post.copyWith(project: project, admin: admin);
//     }).toList();
//   }
// }