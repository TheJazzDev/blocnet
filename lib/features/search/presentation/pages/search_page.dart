import 'package:blocnet/features/projects/data/models/post_type_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../providers/search_provider.dart';
import '../../../projects/data/models/project_model.dart';
import '../../../projects/data/models/post_model.dart';
import '../../../../core/routes/route_names.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final searchProvider = context.read<SearchProvider>();
    searchProvider.loadRecentSearches();
    searchProvider.loadCategories();
    searchProvider.loadTrendingProjects();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchProvider = context.watch<SearchProvider>();

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          decoration: InputDecoration(
            hintText: 'Search projects, posts...',
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      searchProvider.clearResults();
                    },
                  )
                : null,
          ),
          onChanged: (value) {
            setState(() {});
          },
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              searchProvider.search(value);
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              if (_searchController.text.trim().isNotEmpty) {
                searchProvider.search(_searchController.text);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: searchProvider.currentFilter == SearchFilter.all,
                  onSelected: (_) => searchProvider.setFilter(SearchFilter.all),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Projects'),
                  selected:
                      searchProvider.currentFilter == SearchFilter.projects,
                  onSelected: (_) =>
                      searchProvider.setFilter(SearchFilter.projects),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Posts'),
                  selected: searchProvider.currentFilter == SearchFilter.posts,
                  onSelected: (_) =>
                      searchProvider.setFilter(SearchFilter.posts),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _buildContent(searchProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(SearchProvider searchProvider) {
    if (searchProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (searchProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${searchProvider.error}'),
          ],
        ),
      );
    }

    // Show search results
    if (searchProvider.projectResults.isNotEmpty ||
        searchProvider.postResults.isNotEmpty) {
      return _buildResults(searchProvider);
    }

    // Show recent searches and trending
    return _buildSuggestions(searchProvider);
  }

  Widget _buildResults(SearchProvider searchProvider) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Projects
        if (searchProvider.projectResults.isNotEmpty &&
            (searchProvider.currentFilter == SearchFilter.all ||
                searchProvider.currentFilter == SearchFilter.projects)) ...[
          const Text(
            'Projects',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...searchProvider.projectResults.map((project) => _buildProjectCard(project)),
          const SizedBox(height: 24),
        ],

        // Posts
        if (searchProvider.postResults.isNotEmpty &&
            (searchProvider.currentFilter == SearchFilter.all ||
                searchProvider.currentFilter == SearchFilter.posts)) ...[
          const Text(
            'Posts',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...searchProvider.postResults.map((post) => _buildPostCard(post)),
        ],

        // No results
        if (searchProvider.projectResults.isEmpty &&
            searchProvider.postResults.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No results found',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSuggestions(SearchProvider searchProvider) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Recent Searches
        if (searchProvider.recentSearches.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Searches',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => searchProvider.clearRecentSearches(),
                child: const Text('Clear'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...searchProvider.recentSearches.map(
            (query) => ListTile(
              leading: const Icon(Icons.history),
              title: Text(query),
              onTap: () {
                _searchController.text = query;
                searchProvider.search(query);
              },
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Categories
        if (searchProvider.categories.isNotEmpty) ...[
          const Text(
            'Browse by Category',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: searchProvider.categories.map(
              (category) => ActionChip(
                label: Text(category),
                onPressed: () => searchProvider.searchByCategory(category),
              ),
            ).toList(),
          ),
          const SizedBox(height: 24),
        ],

        // Trending Projects
        if (searchProvider.projectResults.isNotEmpty) ...[
          const Text(
            'Trending Projects',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...searchProvider.projectResults.map((project) => _buildProjectCard(project)),
        ],
      ],
    );
  }

  Widget _buildProjectCard(Project project) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage:
              project.logo.isNotEmpty ? NetworkImage(project.logo) : null,
          child: project.logo.isEmpty
              ? Text(project.name[0].toUpperCase())
              : null,
        ),
        title: Text(
          project.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              project.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${project.followersCount} followers • ${project.category}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.pushNamed(
            context,
            RouteNames.projectDetail,
            arguments: project.id,
          );
        },
      ),
    );
  }

  Widget _buildPostCard(Post post) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getPostTypeColor(post.type).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getPostTypeIcon(post.type),
            color: _getPostTypeColor(post.type),
          ),
        ),
        title: Text(
          post.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              post.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${post.likesCount} likes • ${timeago.format(post.createdAt)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.pushNamed(
            context,
            RouteNames.postDetail,
            arguments: post.id,
          );
        },
      ),
    );
  }

  IconData _getPostTypeIcon(PostType type) {
    if (type == PostType.update) {
      return Icons.update;
    } else if (type == PostType.announcement) {
      return Icons.campaign;
    } else if (type == PostType.urgent) {
      return Icons.priority_high;
    }
    return Icons.article; // default
  }

  Color _getPostTypeColor(PostType type) {
    if (type == PostType.update) {
      return Colors.blue;
    } else if (type == PostType.announcement) {
      return Colors.orange;
    } else if (type == PostType.urgent) {
      return Colors.red;
    }
    return Colors.grey; // default
  }
}
