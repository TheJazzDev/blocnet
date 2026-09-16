/// Input checks and conversion for the BNP send form. The backend is the
/// authority (balance, blocks, deactivated members); this only catches what
/// is obviously wrong before a round trip.
library;

final RegExp _usernamePattern = RegExp(r'^@?[a-zA-Z0-9_]{3,24}$');

/// `@Alice` / `alice ` -> `alice`; null when it is not a valid username.
String? normalizePointsRecipient(String input) {
  final trimmed = input.trim();
  if (!_usernamePattern.hasMatch(trimmed)) return null;
  return trimmed.replaceFirst('@', '').toLowerCase();
}

/// Decimal BNP amount -> whole atomic units as a string (`1.5` -> `1500`
/// with 3 decimals). Null when it is not a positive amount in that precision.
String? pointsAmountToAtomic(String input, {int decimals = 3}) {
  final value = input.trim();
  final match = RegExp(r'^(\d+)(?:\.(\d+))?$').firstMatch(value);
  if (match == null) return null;
  final fraction = match.group(2) ?? '';
  if (fraction.length > decimals) return null;
  final atomic = BigInt.parse(
    '${match.group(1)}${fraction.padRight(decimals, '0')}',
  );
  if (atomic <= BigInt.zero) return null;
  return atomic.toString();
}

/// First problem with the form, or null when it can be submitted.
String? validatePointsTransfer({
  required String recipient,
  required String amount,
  required String available,
  String? ownUsername,
  int decimals = 3,
}) {
  if (recipient.trim().isEmpty) {
    return 'Enter the @username of the member to send to.';
  }
  final username = normalizePointsRecipient(recipient);
  if (username == null) {
    return 'Enter a valid @username (3-24 letters, numbers, underscores).';
  }
  final own = ownUsername?.trim().toLowerCase();
  if (own != null && own.isNotEmpty && own == username) {
    return 'You cannot send BNP to yourself.';
  }

  final atomic = pointsAmountToAtomic(amount, decimals: decimals);
  if (atomic == null) {
    return 'Enter an amount greater than zero (up to $decimals decimals).';
  }
  final balance = pointsAmountToAtomic(available, decimals: decimals);
  if (balance == null || BigInt.parse(atomic) > BigInt.parse(balance)) {
    return 'Amount is more than your BNP balance.';
  }
  return null;
}
