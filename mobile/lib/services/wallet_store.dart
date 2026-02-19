import 'package:blocnet/features/wallet/data/models/wallet_models.dart';
import 'package:blocnet/features/wallet/data/repositories/wallet_api_repository.dart';
import 'package:flutter/material.dart';

class WalletStore extends ChangeNotifier {
  WalletStore({WalletApiRepository? repository})
      : _repository = repository ?? WalletApiRepository();

  final WalletApiRepository _repository;

  WalletSnapshot? _snapshot;
  List<WalletTransaction> _transactions = const [];
  bool _isLoadingSummary = false;
  bool _isLoadingTransactions = false;
  String? _lastError;

  WalletSnapshot? get snapshot => _snapshot;
  List<WalletTransaction> get transactions => List.unmodifiable(_transactions);
  bool get isLoadingSummary => _isLoadingSummary;
  bool get isLoadingTransactions => _isLoadingTransactions;
  String? get lastError => _lastError;

  Future<void> loadWalletSummary({bool force = false}) async {
    if (_isLoadingSummary) return;
    if (!force && _snapshot != null) return;

    _isLoadingSummary = true;
    notifyListeners();

    try {
      _snapshot = await _repository.fetchWalletSummary();
      _lastError = null;
    } catch (error) {
      _lastError = error.toString();
    } finally {
      _isLoadingSummary = false;
      notifyListeners();
    }
  }

  Future<void> loadTransactions({bool force = false}) async {
    if (_isLoadingTransactions) return;
    if (!force && _transactions.isNotEmpty) return;

    _isLoadingTransactions = true;
    notifyListeners();

    try {
      _transactions =
          await _repository.fetchTransactions(limit: 100, offset: 0);
      _lastError = null;
    } catch (error) {
      _lastError = error.toString();
    } finally {
      _isLoadingTransactions = false;
      notifyListeners();
    }
  }

  Future<void> refreshAll() async {
    await Future.wait([
      loadWalletSummary(force: true),
      loadTransactions(force: true),
    ]);
  }

  void clear() {
    _snapshot = null;
    _transactions = const [];
    _lastError = null;
    notifyListeners();
  }
}
