import 'package:blocnet/features/projects/data/models/post_model.dart';
import 'package:blocnet/services/api/api_client.dart';

class PostsApiRepository {
  PostsApiRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<Post>> fetchPosts({int limit = 200, int offset = 0}) async {
    final response = await _apiClient.get(
      '/posts',
      query: {
        'limit': '$limit',
        'offset': '$offset',
      },
    );

    if (response is! List) {
      return [];
    }

    return response
        .whereType<Map<String, dynamic>>()
        .map(Post.fromApi)
        .toList();
  }

  Future<Post?> createPost(Post post) async {
    final response = await _apiClient.post(
      '/projects/${post.projectId}/posts',
      body: {
        'title': post.title,
        'contentMd': post.content,
        'urgency': _priorityToUrgency(post.priority),
      },
    );

    if (response is! Map<String, dynamic>) {
      return null;
    }

    return Post.fromApi(response);
  }

  Future<Post?> updatePost(Post post) async {
    final response = await _apiClient.patch(
      '/posts/${post.id}',
      body: {
        'title': post.title,
        'contentMd': post.content,
        'urgency': _priorityToUrgency(post.priority),
      },
    );

    if (response is! Map<String, dynamic>) {
      return null;
    }

    return Post.fromApi(response);
  }

  String _priorityToUrgency(dynamic priority) {
    final value = priority.toString().toLowerCase();

    if (value.contains('high')) return 'high';
    if (value.contains('mid') || value.contains('medium')) return 'medium';
    return 'low';
  }
}
