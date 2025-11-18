import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/settings_model.dart';

class SettingsProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AppSettings _settings = AppSettings();
  bool _isLoading = false;
  String? _error;

  AppSettings get settings => _settings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadSettings(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['settings'] != null) {
          _settings = AppSettings.fromJson(data['settings']);
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateSettings(String userId, AppSettings newSettings) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore.collection('users').doc(userId).update({
        'settings': newSettings.toJson(),
      });

      _settings = newSettings;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}
