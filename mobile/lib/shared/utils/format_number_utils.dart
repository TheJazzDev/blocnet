import 'package:intl/intl.dart';

String formatGroupedNumber(
  num? value, {
  int maxDecimals = 2,
  int minDecimals = 0,
}) {
  if (value == null) return '0';
  if (value.isNaN || value.isInfinite) return value.toString();

  final safeMaxDecimals = maxDecimals < 0 ? 0 : maxDecimals;
  final safeMinDecimals = minDecimals.clamp(0, safeMaxDecimals);
  final formatter = NumberFormat.decimalPatternDigits(
    locale: 'en_US',
    decimalDigits: safeMaxDecimals,
  );

  var formatted = formatter.format(value);
  if (safeMaxDecimals == safeMinDecimals) {
    return formatted;
  }

  if (formatted.contains('.')) {
    formatted = formatted.replaceFirst(RegExp(r'0+$'), '');
    if (formatted.endsWith('.')) {
      formatted = formatted.substring(0, formatted.length - 1);
    }
  }

  if (safeMinDecimals > 0) {
    if (!formatted.contains('.')) {
      formatted = '$formatted.${'0' * safeMinDecimals}';
    } else {
      final decimals = formatted.split('.').last.length;
      if (decimals < safeMinDecimals) {
        formatted = '$formatted${'0' * (safeMinDecimals - decimals)}';
      }
    }
  }

  return formatted;
}

String formatGroupedAmount(
  String value, {
  int maxDecimals = 6,
  int minDecimals = 0,
  bool absolute = false,
}) {
  final parsed = num.tryParse(value.trim());
  if (parsed == null) return value;
  final normalized = absolute ? parsed.abs() : parsed;
  return formatGroupedNumber(
    normalized,
    maxDecimals: maxDecimals,
    minDecimals: minDecimals,
  );
}
