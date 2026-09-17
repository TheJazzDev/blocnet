final RegExp _evmAddressPattern = RegExp(r'^0x[a-fA-F0-9]{40}$');
final RegExp _usernamePattern = RegExp(r'^@?[a-zA-Z0-9_]{3,24}$');
final RegExp _amountPattern = RegExp(r'^\d+(\.\d{1,18})?$');

/// First problem with a token send, or null when it can go.
///
/// [inBlocnet] sends accept an @username or an address; on-chain
/// withdrawals need an address and a reason.
String? validateTokenSend({
  required bool inBlocnet,
  required String recipient,
  required String amount,
  required String reason,
}) {
  final to = recipient.trim();
  final value = amount.trim();

  if (inBlocnet) {
    if (to.isEmpty) return 'Enter an @username or wallet address.';
    if (!_evmAddressPattern.hasMatch(to)) {
      if (to.toLowerCase().startsWith('0x')) {
        return 'Enter a valid wallet address.';
      }
      if (!_usernamePattern.hasMatch(to)) {
        return 'Enter a valid @username or wallet address.';
      }
    }
  } else if (!_evmAddressPattern.hasMatch(to)) {
    return 'Enter a valid wallet address (0x…).';
  }
  if (!_amountPattern.hasMatch(value)) {
    return 'Enter an amount, up to 18 decimals.';
  }
  final parsed = num.tryParse(value);
  if (parsed == null || parsed <= 0) {
    return 'Amount must be greater than zero.';
  }
  if (!inBlocnet && reason.trim().length < 3) {
    return 'Add a reason (3 characters or more).';
  }
  return null;
}

/// The username in [value] (lower case, no @), or null when it is an
/// address or not a valid username.
String? tokenSendUsername(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty || _evmAddressPattern.hasMatch(trimmed)) return null;
  if (!_usernamePattern.hasMatch(trimmed)) return null;
  return trimmed.replaceFirst(RegExp('^@'), '').toLowerCase();
}
