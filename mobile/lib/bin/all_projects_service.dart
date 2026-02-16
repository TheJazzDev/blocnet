// import '../dummy/dummy_admins.dart';
// import '../dummy/dummy_posts.dart';
// import '../dummy/dummy_projects.dart';
// import '../models/admin_model.dart';
// import '../models/project_model.dart';

// class AllProjectsService {
//   // Enrich posts with project and admin details
//   static List<Project> getAllProjects() {
//     return dummyProjects.map((project) {
//       Admin? admin;

//       final relatedPosts = dummyPosts
//           .where((post) => project.postIds.contains(post.id))
//           .toList();

//       // try {
//       //   post = dummyPosts.firstWhere((p) => p.id == project.id);
//       // } catch (e) {
//       //   post = null;
//       // }

//       try {
//         admin = dummyAdmins.firstWhere((a) => a.id == project.adminId);
//       } catch (e) {
//         admin = null;
//       }

//       return project.copyWith(posts: relatedPosts, admin: admin);
//     }).toList();
//   }
// }
