import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../projects/data/models/project_model.dart';
import '../../../projects/data/models/post_model.dart';
import '../../data/repositories/search_repository.dart';

enum SearchFilter { all, projects, posts }

class SearchProvider with ChangeNotifier {
  final SearchRepository _repository = SearchRepository();

  List<Project> _projectResults = [];
  List<Post> _postResults = [];
  List<String> _recentSearches = [];
  List<String> _categories = [];
  SearchFilter _currentFilter = SearchFilter.all;
  String? _selectedCategory;
  bool _isLoading = false;
  String? _error;

  List<Project> get projectResults => _projectResults;
  List<Post> get postResults => _postResults;
  List<String> get recentSearches => _recentSearches;
  List<String> get categories => _categories;
  SearchFilter get currentFilter => _currentFilter;
  String? get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load recent searches from SharedPreferences
  Future<void> loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    _recentSearches = prefs.getStringList('recent_searches') ?? [];
    notifyListeners();
  }

  // Load categories
  Future<void> loadCategories() async {
    try {
      _categories = await _repository.getCategories();
      notifyListeners();
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  // Add to recent searches
  Future<void> _addToRecentSearches(String query) async {
    if (query.isEmpty) return;

    // Remove if already exists
    _recentSearches.remove(query);

    // Add to beginning
    _recentSearches.insert(0, query);

    // Keep only last 10 searches
    if (_recentSearches.length > 10) {
      _recentSearches = _recentSearches.sublist(0, 10);
    }

    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('recent_searches', _recentSearches);

    notifyListeners();
  }

  // Clear recent searches
  Future<void> clearRecentSearches() async {
    _recentSearches.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recent_searches');
    notifyListeners();
  }

  // Search
  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      _projectResults = [];
      _postResults = [];
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _addToRecentSearches(query);

      if (_currentFilter == SearchFilter.all ||
          _currentFilter == SearchFilter.projects) {
        _projectResults = await _repository.searchProjects(query);
      }

      if (_currentFilter == SearchFilter.all ||
          _currentFilter == SearchFilter.posts) {
        _postResults = await _repository.searchPosts(query);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Search by category
  Future<void> searchByCategory(String category) async {
    try {
      _isLoading = true;
      _error = null;
      _selectedCategory = category;
      notifyListeners();

      _projectResults = await _repository.searchByCategory(category);
      _postResults = [];

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear category filter
  void clearCategory() {
    _selectedCategory = null;
    _projectResults = [];
    _postResults = [];
    notifyListeners();
  }

  // Set filter
  void setFilter(SearchFilter filter) {
    _currentFilter = filter;
    notifyListeners();
  }

  // Clear results
  void clearResults() {
    _projectResults = [];
    _postResults = [];
    _selectedCategory = null;
    _error = null;
    notifyListeners();
  }

  // Get trending projects
  Future<void> loadTrendingProjects() async {
    try {
      _isLoading = true;
      notifyListeners();

      _projectResults = await _repository.getTrendingProjects();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
}
