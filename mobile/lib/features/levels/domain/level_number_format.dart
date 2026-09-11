/// Compact number formatting shared by the levels UI.
///
/// Values are kept as [BigInt] because BNP totals arrive as decimal strings
/// that can exceed 2^53.
library;

/// Parses a raw numeric string (as sent by the API) into a [BigInt].
/// Non-numeric input yields zero so the UI never throws on bad data.
BigInt parseBigInt(String? raw) {
  if (raw == null) return BigInt.zero;
  final cleaned = raw.trim().replaceAll(',', '');
  if (cleaned.isEmpty) return BigInt.zero;
  final asInt = BigInt.tryParse(cleaned);
  if (asInt != null) return asInt;
  final asDouble = double.tryParse(cleaned);
  if (asDouble == null || asDouble.isNaN || asDouble.isInfinite) {
    return BigInt.zero;
  }
  return BigInt.from(asDouble.truncate());
}

/// `1234` → `1,234`, `12500` → `12.5K`, `2000000` → `2M`.
String formatCompact(BigInt value) {
  final million = BigInt.from(1000000);
  final thousand = BigInt.from(1000);
  if (value >= million) return '${_scaled(value, million)}M';
  if (value >= thousand) return '${_scaled(value, thousand)}K';
  return formatGrouped(value);
}

/// Same as [formatCompact] but takes the raw API string.
String formatCompactRaw(String? raw) => formatCompact(parseBigInt(raw));

/// Thousands-grouped integer, e.g. `1234567` → `1,234,567`.
String formatGrouped(BigInt value) {
  final negative = value.isNegative;
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final remaining = digits.length - i;
    buffer.write(digits[i]);
    if (remaining > 1 && remaining % 3 == 1) buffer.write(',');
  }
  return negative ? '-$buffer' : buffer.toString();
}

String _scaled(BigInt value, BigInt unit) {
  final whole = value ~/ unit;
  final tenth = ((value % unit) * BigInt.from(10)) ~/ unit;
  return tenth == BigInt.zero ? '$whole' : '$whole.$tenth';
}
