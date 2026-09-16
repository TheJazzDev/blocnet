import 'dart:async';

import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/auth/data/repositories/users_api_repository.dart';
import 'package:blocnet/features/profile/data/models/profile_search_result_model.dart';
import 'package:blocnet/features/wallet/presentation/widgets/wallet_form_field.dart';
import 'package:flutter/material.dart';

typedef ProfileSearch = Future<List<ProfileSearchResult>> Function(
  String query,
);

/// @username input for BNP sends, with member suggestions from
/// `/profiles/search` as the user types. Picking one fills the field.
class PointsRecipientField extends StatefulWidget {
  const PointsRecipientField({
    super.key,
    required this.controller,
    this.search,
    this.ownUsername,
  });

  final TextEditingController controller;

  /// Injectable for tests; defaults to [UsersApiRepository.searchProfiles].
  final ProfileSearch? search;

  /// Hidden from suggestions (you cannot send to yourself).
  final String? ownUsername;

  @override
  State<PointsRecipientField> createState() => _PointsRecipientFieldState();
}

class _PointsRecipientFieldState extends State<PointsRecipientField> {
  static const _debounce = Duration(milliseconds: 300);

  Timer? _timer;
  List<ProfileSearchResult> _results = const [];
  int _requestId = 0;

  late final ProfileSearch _search = widget.search ??
      ((query) => UsersApiRepository().searchProfiles(query: query, limit: 5));

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _timer?.cancel();
    final query = value.trim().replaceFirst('@', '');
    if (query.length < 2) {
      if (_results.isNotEmpty) setState(() => _results = const []);
      return;
    }
    _timer = Timer(_debounce, () => _lookup(query));
  }

  Future<void> _lookup(String query) async {
    final requestId = ++_requestId;
    try {
      final rows = await _search(query);
      if (!mounted || requestId != _requestId) return;
      final own = widget.ownUsername?.toLowerCase();
      setState(() {
        _results = rows
            .where((row) => (row.username ?? '').isNotEmpty)
            .where((row) => row.username!.toLowerCase() != own)
            .take(5)
            .toList();
      });
    } catch (_) {
      // Suggestions are a convenience; the backend validates the username.
      if (mounted && requestId == _requestId) {
        setState(() => _results = const []);
      }
    }
  }

  void _pick(ProfileSearchResult row) {
    _timer?.cancel();
    _requestId++;
    widget.controller.text = '@${row.username}';
    widget.controller.selection = TextSelection.collapsed(
      offset: widget.controller.text.length,
    );
    setState(() => _results = const []);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WalletFormField(
          fieldKey: const ValueKey('points-recipient'),
          label: 'Recipient (@username)',
          controller: widget.controller,
          hint: '@username',
          onChanged: _onChanged,
        ),
        if (_results.isNotEmpty) ...[
          const SizedBox(height: AppSpace.xs),
          Container(
            decoration: BoxDecoration(
              color: AppColors.bgElevated,
              borderRadius: BorderRadius.circular(AppRadius.mdValue),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              children: _results.map(_suggestion).toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _suggestion(ProfileSearchResult row) {
    return InkWell(
      onTap: () => _pick(row),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md,
          vertical: AppSpace.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                row.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.custom(
                  color: AppColors.textPrimary,
                  size: AppText.labelSize,
                  weight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            Text(
              '@${row.username}',
              style: AppTypography.custom(
                color: AppColors.textMuted,
                size: AppText.captionSize,
                weight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
