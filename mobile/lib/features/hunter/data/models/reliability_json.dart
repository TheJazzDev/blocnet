/// Tolerant readers for the reliability payloads.
///
/// The backend is the source of truth for every number here; these only turn
/// JSON into Dart without throwing on a missing or oddly typed field, so an
/// older or newer backend degrades to "unknown" rather than a crash.
library;

Map<String, dynamic> jsonMap(Object? raw) {
  if (raw is! Map) return const <String, dynamic>{};
  return raw.map((key, value) => MapEntry(key.toString(), value));
}

List<Map<String, dynamic>> jsonMapList(Object? raw) {
  if (raw is! List) return const <Map<String, dynamic>>[];
  return raw.whereType<Map>().map(jsonMap).toList(growable: false);
}

String jsonString(Object? raw, {String fallback = ''}) {
  if (raw == null) return fallback;
  return raw.toString();
}

String? jsonStringOrNull(Object? raw) {
  if (raw == null) return null;
  final value = raw.toString();
  return value.isEmpty ? null : value;
}

int jsonInt(Object? raw, {int fallback = 0}) {
  if (raw is num) return raw.toInt();
  if (raw is String) return int.tryParse(raw) ?? fallback;
  return fallback;
}

int? jsonIntOrNull(Object? raw) {
  if (raw is num) return raw.toInt();
  if (raw is String) return int.tryParse(raw);
  return null;
}

double? jsonDoubleOrNull(Object? raw) {
  if (raw is num) return raw.toDouble();
  if (raw is String) return double.tryParse(raw);
  return null;
}

/// BigInt amounts travel as decimal strings (backend BigInt rule).
BigInt jsonBigInt(Object? raw) {
  if (raw is int) return BigInt.from(raw);
  if (raw is String) return BigInt.tryParse(raw.trim()) ?? BigInt.zero;
  return BigInt.zero;
}

DateTime? jsonDateOrNull(Object? raw) {
  if (raw is! String || raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}

DateTime jsonDate(Object? raw) {
  return jsonDateOrNull(raw) ??
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}
