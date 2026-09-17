import 'dart:async';

import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/services/api/api_client.dart';
import 'package:flutter/material.dart';

enum UsernameStatus { idle, checking, available, taken, invalid }

/// Debounced `/users/check-username` lookup for the sign-up form.
class UsernameAvailability extends ChangeNotifier {
  UsernameAvailability({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  static final RegExp pattern = RegExp(r'^[a-z0-9_]{3,24}$');

  final ApiClient _apiClient;
  Timer? _debounce;
  UsernameStatus _status = UsernameStatus.idle;
  bool _disposed = false;

  UsernameStatus get status => _status;
  bool get isAvailable => _status == UsernameStatus.available;

  void onChanged(String value) {
    final raw = value.trim().toLowerCase();
    _debounce?.cancel();

    if (raw.isEmpty) return _set(UsernameStatus.idle);
    if (!pattern.hasMatch(raw)) return _set(UsernameStatus.invalid);

    _set(UsernameStatus.checking);
    _debounce = Timer(const Duration(milliseconds: 500), () => _check(raw));
  }

  Future<void> _check(String username) async {
    try {
      final response = await _apiClient.get(
        '/users/check-username',
        query: {'username': username},
      );
      if (response is Map<String, dynamic>) {
        _set(response['available'] == true
            ? UsernameStatus.available
            : UsernameStatus.taken);
      }
    } catch (_) {
      _set(UsernameStatus.idle);
    }
  }

  void _set(UsernameStatus next) {
    if (_disposed || next == _status) return;
    _status = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    super.dispose();
  }
}

/// The one line under the username field: checking, available, taken, or
/// the rules.
class UsernameHint extends StatelessWidget {
  const UsernameHint({super.key, required this.status});

  final UsernameStatus status;

  @override
  Widget build(BuildContext context) {
    final (Widget? lead, String text, Color color) = switch (status) {
      UsernameStatus.checking => (
          SizedBox(
            width: AppIcon.xs - 2,
            height: AppIcon.xs - 2,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: AppColors.textFaint,
            ),
          ),
          'Checking…',
          AppColors.textFaint,
        ),
      UsernameStatus.available => (
          Icon(Icons.check_circle_outline,
              size: AppIcon.xs, color: AppColors.successColor),
          'Available',
          AppColors.successColor,
        ),
      UsernameStatus.taken => (
          Icon(Icons.cancel_outlined,
              size: AppIcon.xs, color: AppColors.error500),
          'Already taken',
          AppColors.error500,
        ),
      UsernameStatus.invalid => (
          null,
          '3–24 characters: a–z, 0–9 and _',
          AppColors.warning500,
        ),
      UsernameStatus.idle => (
          null,
          'Lowercase, unique, and it cannot be changed later.',
          AppColors.textFaint,
        ),
    };
    return Padding(
      padding: const EdgeInsets.only(left: AppSpace.xs, top: AppSpace.xs),
      child: Row(
        children: [
          if (lead != null) ...[lead, AppSpace.wGapXs],
          Expanded(child: Text(text, style: AppText.caption(color))),
        ],
      ),
    );
  }
}
