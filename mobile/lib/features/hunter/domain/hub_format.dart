/// Small wording helpers for the Hub. Everything here states a fact the
/// platform has; none of it counts down.
library;

import 'package:blocnet/shared/utils/format_number_utils.dart';

/// `8,412`.
String groupedCount(int value) => formatGroupedNumber(value, maxDecimals: 0);

/// `1 member` / `31 members`.
String counted(int n, String singular, [String? plural]) {
  final noun = n == 1 ? singular : (plural ?? '${singular}s');
  return '${groupedCount(n)} $noun';
}

/// `3h ago`, `1d ago` — the condensed row's "last touched".
String shortAgo(DateTime at, DateTime now) {
  final diff = now.difference(at);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}

/// `today`, `1 day ago`, `19 days ago`.
String daysAgo(int days) {
  if (days <= 0) return 'today';
  return '${counted(days, 'day')} ago';
}

/// [daysAgo] measured between two instants.
String daysAgoSince(DateTime at, DateTime now) =>
    daysAgo(now.difference(at).inDays);

/// An atomic token amount in whole units: `18,240` for large amounts, up to
/// two decimals below 100.
String formatAtomic(BigInt atomic, int decimals) {
  if (atomic <= BigInt.zero) return '0';
  final scale = BigInt.from(10).pow(decimals < 0 ? 0 : decimals);
  final whole = atomic ~/ scale;
  if (whole >= BigInt.from(100)) {
    return formatGroupedNumber(whole.toInt(), maxDecimals: 0);
  }
  final value = atomic / scale;
  return formatGroupedNumber(value, maxDecimals: 2);
}

/// `18,240 BNP`, or null when there is nothing to state.
String? formatTips(BigInt atomic, String? code, int? decimals) {
  if (atomic <= BigInt.zero) return null;
  final amount = formatAtomic(atomic, decimals ?? 18);
  final unit = (code ?? '').trim();
  return unit.isEmpty ? amount : '$amount $unit';
}

const List<String> _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// `20 Aug` in the viewer's time.
String dayMonth(DateTime at) {
  final local = at.toLocal();
  return '${local.day} ${_months[local.month - 1]}';
}

/// `High` / `Medium` / `Low` from the backend's urgency string.
String urgencyLabel(String priority) {
  switch (priority.trim().toLowerCase()) {
    case 'high':
      return 'High';
    case 'medium':
    case 'mid':
      return 'Medium';
    default:
      return 'Low';
  }
}

const List<String> _spelled = [
  'zero', 'one', 'two', 'three', 'four', 'five', //
  'six', 'seven', 'eight', 'nine', 'ten',
];

/// `two` up to ten, digits after.
String spelledCount(int n) =>
    n >= 0 && n < _spelled.length ? _spelled[n] : groupedCount(n);

String capitalized(String text) =>
    text.isEmpty ? text : '${text[0].toUpperCase()}${text.substring(1)}';
