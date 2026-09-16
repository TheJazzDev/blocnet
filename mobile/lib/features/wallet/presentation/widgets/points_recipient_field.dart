import 'package:blocnet/features/wallet/presentation/widgets/wallet_form_field.dart';
import 'package:blocnet/shared/widgets/username_suggest_field.dart';
import 'package:flutter/material.dart';

export 'package:blocnet/shared/widgets/username_suggest_field.dart'
    show ProfileSearch;

/// @username input for BNP sends, with member suggestions from
/// `/profiles/search` as the user types. Picking one fills the field.
class PointsRecipientField extends StatelessWidget {
  const PointsRecipientField({
    super.key,
    required this.controller,
    this.search,
    this.ownUsername,
  });

  final TextEditingController controller;

  /// Injectable for tests; defaults to the profile search endpoint.
  final ProfileSearch? search;

  /// Hidden from suggestions (you cannot send to yourself).
  final String? ownUsername;

  @override
  Widget build(BuildContext context) {
    return UsernameSuggestField(
      controller: controller,
      search: search,
      excludeUsername: ownUsername,
      inputBuilder: (context, onChanged) => WalletFormField(
        fieldKey: const ValueKey('points-recipient'),
        label: 'Recipient (@username)',
        controller: controller,
        hint: '@username',
        onChanged: onChanged,
      ),
    );
  }
}
