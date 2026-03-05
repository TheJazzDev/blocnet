import 'package:blocnet/features/projects/data/models/primary_tag_model.dart';
import 'package:blocnet/features/projects/data/models/secondary_tag_model.dart';
import 'package:blocnet/features/projects/data/repositories/tags_api_repository.dart';
import 'package:flutter/material.dart';

class TagsStore extends ChangeNotifier {
  TagsStore({TagsApiRepository? repository})
      : _repository = repository ?? TagsApiRepository();

  final TagsApiRepository _repository;

  List<PrimaryTag> _primaryTags = const [];
  List<SecondaryTag> _secondaryTags = const [];
  bool _isLoading = false;
  String? _lastError;

  List<PrimaryTag> get primaryTags => List.unmodifiable(_primaryTags);
  List<SecondaryTag> get secondaryTags => List.unmodifiable(_secondaryTags);
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;

  Future<void> fetchOnce() async {
    if (_isLoading || (_primaryTags.isNotEmpty && _secondaryTags.isNotEmpty)) {
      return;
    }
    await refresh();
  }

  Future<void> refresh() async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.fetchPrimaryTags(),
        _repository.fetchSecondaryTags(),
      ]);

      _primaryTags = results[0] as List<PrimaryTag>;
      _secondaryTags = results[1] as List<SecondaryTag>;
      _lastError = null;
    } catch (error) {
      _lastError = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
