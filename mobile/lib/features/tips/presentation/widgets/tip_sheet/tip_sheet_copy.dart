import 'package:blocnet/features/tips/data/models/tip_models.dart';
import 'package:blocnet/services/api/api_client.dart';
import 'package:blocnet/services/engagement/tips_store.dart';

/// Shown when a send fails for a reason the member cannot act on.
const String tipFailedText = 'Tip not sent. Try again.';

final RegExp _amountPattern = RegExp(r'^\d+(\.\d+)?$');

/// Checks the form before anything is sent. Null when it can go.
String? validateTip({
  required String amount,
  required String recipientId,
  required String? ownUserId,
  required TipCurrency? currency,
}) {
  if (ownUserId != null && ownUserId == recipientId) {
    return 'You cannot tip yourself.';
  }
  if (!_amountPattern.hasMatch(amount)) return 'Enter a valid amount.';
  if (currency != null) {
    final parts = amount.split('.');
    final fraction = parts.length > 1 ? parts[1] : '';
    if (fraction.length > currency.decimals) {
      return 'Use up to ${currency.decimals} decimal places.';
    }
  }
  return null;
}

/// What the form says when a send fails. The backend's own sentence for a
/// refused tip (4xx) is kept; server faults and status stubs such as
/// `Request failed (500)` become [tipFailedText].
String tipErrorText(TipsStore store, Object error) {
  if (error is ApiException && (error.statusCode ?? 0) >= 500) {
    return tipFailedText;
  }
  final message = store.describeError(error).trim();
  if (message.isEmpty ||
      message.startsWith('Request failed') ||
      message.startsWith('[') ||
      message.startsWith('{')) {
    return tipFailedText;
  }
  return message;
}

/// `0` or empty minimums read as "no minimum".
String? tipMinimumLabel(TipCurrencyFeePolicy? policy, String symbol) {
  final min = double.tryParse(policy?.minTip ?? '') ?? 0;
  if (min <= 0) return null;
  return 'Min ${policy!.minTip} $symbol';
}

/// `1.5%` — trailing zeros dropped.
String tipFeeLabel(TipCurrencyFeePolicy? policy) {
  final pct = (policy?.feeBps ?? 0) / 100;
  final text = pct == pct.roundToDouble()
      ? pct.toStringAsFixed(0)
      : pct.toStringAsFixed(2).replaceFirst(RegExp(r'0$'), '');
  return '$text%';
}

String tipFeePayer(TipCurrencyFeePolicy? policy) =>
    policy?.senderPaysFee == false ? 'Recipient pays' : 'You pay';

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// `Sep 17, 14:02`.
String tipDateLabel(DateTime value) {
  final local = value.toLocal();
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  return '${_months[local.month - 1]} ${local.day}, $hh:$mm';
}
