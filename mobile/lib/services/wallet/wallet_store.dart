import 'package:blocnet/features/wallet/data/models/wallet_models.dart';
import 'package:blocnet/features/wallet/data/repositories/wallet_api_repository.dart';
import 'package:blocnet/services/api/api_error.dart';
import 'package:blocnet/services/api/api_client.dart';
import 'dart:convert';
import 'package:flutter/material.dart';

class WalletStore extends ChangeNotifier {
  WalletStore({WalletApiRepository? repository})
      : _repository = repository ?? WalletApiRepository();

  static const String walletOnboardingSeenKeyPrefix =
      'wallet_onboarding_seen_v1_';

  final WalletApiRepository _repository;

  WalletSnapshot? _snapshot;
  List<WalletTransaction> _transactions = const [];
  List<WalletWithdrawalRequest> _withdrawals = const [];
  final Map<String, List<WalletTransaction>> _transactionsByAsset = {};
  final Map<String, List<WalletWithdrawalRequest>> _withdrawalsByAsset = {};
  bool _isLoadingSummary = false;
  bool _isLoadingTransactions = false;
  bool _isLoadingWithdrawals = false;
  final Set<String> _loadingTransactionsAssets = {};
  final Set<String> _loadingWithdrawalsAssets = {};
  bool _isSubmittingInternalTransfer = false;
  bool _isSubmittingWithdrawal = false;
  String? _lastError;

  WalletSnapshot? get snapshot => _snapshot;
  List<WalletTransaction> get transactions => List.unmodifiable(_transactions);
  List<WalletWithdrawalRequest> get withdrawals =>
      List.unmodifiable(_withdrawals);
  bool get isLoadingSummary => _isLoadingSummary;
  bool get isLoadingTransactions => _isLoadingTransactions;
  bool get isLoadingWithdrawals => _isLoadingWithdrawals;
  bool get isSubmittingInternalTransfer => _isSubmittingInternalTransfer;
  bool get isSubmittingWithdrawal => _isSubmittingWithdrawal;
  String? get lastError => _lastError;
  List<String> get supportedAssets =>
      _snapshot?.supportedAssets.isNotEmpty == true
          ? _snapshot!.supportedAssets
          : const ['BNT'];

  WalletAssetBalance? findAsset(String assetCode) {
    return _snapshot?.findAsset(assetCode);
  }

  List<WalletTransaction> transactionsForAsset(String assetCode) {
    final key = _assetKey(assetCode);
    return List.unmodifiable(_transactionsByAsset[key] ?? const []);
  }

  List<WalletWithdrawalRequest> withdrawalsForAsset(String assetCode) {
    final key = _assetKey(assetCode);
    return List.unmodifiable(_withdrawalsByAsset[key] ?? const []);
  }

  bool isLoadingTransactionsForAsset(String assetCode) {
    return _loadingTransactionsAssets.contains(_assetKey(assetCode));
  }

  bool isLoadingWithdrawalsForAsset(String assetCode) {
    return _loadingWithdrawalsAssets.contains(_assetKey(assetCode));
  }

  bool canTransferAsset(String assetCode) {
    final snapshot = _snapshot;
    if (snapshot == null) {
      return assetCode.toUpperCase() == 'BNT';
    }
    return snapshot.isTransferEnabledFor(assetCode);
  }

  bool canWithdrawAsset(String assetCode) {
    final snapshot = _snapshot;
    if (snapshot == null) {
      return assetCode.toUpperCase() == 'BNT';
    }
    return snapshot.isWithdrawalEnabledFor(assetCode);
  }

  Future<void> loadWalletSummary({bool force = false}) async {
    if (_isLoadingSummary) return;
    if (!force && _snapshot != null) return;

    _isLoadingSummary = true;
    notifyListeners();

    try {
      _snapshot = await _repository.fetchWalletSummary();
      _lastError = null;
    } catch (error) {
      _lastError = describeApiError(
        error,
        fallback: 'Unable to load wallet summary right now.',
      );
    } finally {
      _isLoadingSummary = false;
      notifyListeners();
    }
  }

  Future<void> loadTransactions({bool force = false, String? asset}) async {
    final selectedAsset = asset == null ? null : _assetKey(asset);
    if (selectedAsset == null) {
      if (_isLoadingTransactions) return;
      if (!force && _transactions.isNotEmpty) return;
      _isLoadingTransactions = true;
    } else {
      if (_loadingTransactionsAssets.contains(selectedAsset)) return;
      if (!force &&
          (_transactionsByAsset[selectedAsset]?.isNotEmpty ?? false)) {
        return;
      }
      _loadingTransactionsAssets.add(selectedAsset);
    }

    notifyListeners();

    try {
      final loaded = await _repository.fetchTransactions(
        limit: 100,
        offset: 0,
        asset: selectedAsset,
      );
      if (selectedAsset == null) {
        _transactions = loaded;
      } else {
        _transactionsByAsset[selectedAsset] = loaded;
      }
      _lastError = null;
    } catch (error) {
      _lastError = describeApiError(
        error,
        fallback: 'Unable to load wallet transactions right now.',
      );
    } finally {
      if (selectedAsset == null) {
        _isLoadingTransactions = false;
      } else {
        _loadingTransactionsAssets.remove(selectedAsset);
      }
      notifyListeners();
    }
  }

  Future<void> loadWithdrawals({bool force = false, String? asset}) async {
    final selectedAsset = asset == null ? null : _assetKey(asset);
    if (selectedAsset == null) {
      if (_isLoadingWithdrawals) return;
      if (!force && _withdrawals.isNotEmpty) return;
      _isLoadingWithdrawals = true;
    } else {
      if (_loadingWithdrawalsAssets.contains(selectedAsset)) return;
      if (!force && (_withdrawalsByAsset[selectedAsset]?.isNotEmpty ?? false)) {
        return;
      }
      _loadingWithdrawalsAssets.add(selectedAsset);
    }

    notifyListeners();

    try {
      final loaded = await _repository.fetchWithdrawals(
        limit: 50,
        offset: 0,
        asset: selectedAsset,
      );
      if (selectedAsset == null) {
        _withdrawals = loaded;
      } else {
        _withdrawalsByAsset[selectedAsset] = loaded;
      }
      _lastError = null;
    } catch (error) {
      _lastError = describeApiError(
        error,
        fallback: 'Unable to load withdrawals right now.',
      );
    } finally {
      if (selectedAsset == null) {
        _isLoadingWithdrawals = false;
      } else {
        _loadingWithdrawalsAssets.remove(selectedAsset);
      }
      notifyListeners();
    }
  }

  Future<void> loadAssetActivity(
    String assetCode, {
    bool force = false,
  }) async {
    final asset = _assetKey(assetCode);
    await Future.wait([
      loadTransactions(force: force, asset: asset),
      loadWithdrawals(force: force, asset: asset),
    ]);
  }

  Future<void> refreshAsset(String assetCode) async {
    await loadAssetActivity(assetCode, force: true);
  }

  Future<void> refreshAll() async {
    final assetKeys = <String>{
      ..._transactionsByAsset.keys,
      ..._withdrawalsByAsset.keys,
    }.toList();

    await Future.wait([
      loadWalletSummary(force: true),
      loadTransactions(force: true),
      loadWithdrawals(force: true),
      ...assetKeys.map((asset) => loadAssetActivity(asset, force: true)),
    ]);
  }

  Future<WalletTransaction?> createInternalTransfer({
    required String amount,
    String? toUserId,
    String? toUsername,
    String? toAddress,
    String? asset,
    String? note,
    String? idempotencyKey,
  }) async {
    if (_isSubmittingInternalTransfer) return null;

    _isSubmittingInternalTransfer = true;
    notifyListeners();

    try {
      final created = await _repository.createInternalTransfer(
        amount: amount,
        toUserId: toUserId,
        toUsername: toUsername,
        toAddress: toAddress,
        asset: asset,
        note: note,
        idempotencyKey: idempotencyKey,
      );
      _lastError = null;
      await refreshAll();
      return created;
    } catch (error) {
      _lastError = describeError(error);
      rethrow;
    } finally {
      _isSubmittingInternalTransfer = false;
      notifyListeners();
    }
  }

  Future<WalletWithdrawalRequest?> createWithdrawal({
    required String toAddress,
    required String amount,
    required String reason,
    String? asset,
    String? idempotencyKey,
  }) async {
    if (_isSubmittingWithdrawal) return null;

    _isSubmittingWithdrawal = true;
    notifyListeners();

    try {
      final created = await _repository.createWithdrawal(
        toAddress: toAddress,
        amount: amount,
        reason: reason,
        asset: asset,
        idempotencyKey: idempotencyKey,
      );
      _lastError = null;
      await refreshAll();
      return created;
    } catch (error) {
      _lastError = describeError(error);
      rethrow;
    } finally {
      _isSubmittingWithdrawal = false;
      notifyListeners();
    }
  }

  String describeError(Object error) {
    if (error is ApiException) {
      final body = error.responseBody?.trim();
      if (body != null && body.isNotEmpty) {
        try {
          final parsed = jsonDecode(body);
          if (parsed is Map<String, dynamic>) {
            final message = parsed['message']?.toString();
            if (message != null && message.isNotEmpty) {
              return message;
            }
          }
        } catch (_) {
          // no-op; fallback below
        }
      }
      if (error.statusCode != null) {
        return 'Request failed (${error.statusCode})';
      }
      return error.message;
    }
    return error.toString();
  }

  void clear() {
    _snapshot = null;
    _transactions = const [];
    _withdrawals = const [];
    _transactionsByAsset.clear();
    _withdrawalsByAsset.clear();
    _loadingTransactionsAssets.clear();
    _loadingWithdrawalsAssets.clear();
    _lastError = null;
    notifyListeners();
  }

  String _assetKey(String value) => value.trim().toUpperCase();

  String walletOnboardingSeenKeyForUser(String userId) {
    return '$walletOnboardingSeenKeyPrefix$userId';
  }
}
