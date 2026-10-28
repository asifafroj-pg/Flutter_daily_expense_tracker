/// The only JSON parsing helper in the app (coding-style.md §7).
///
/// Never use `(x as T)` casts on untrusted JSON — always go through
/// [safeParse] so a malformed field degrades to `defaultValue` instead of
/// crashing the screen.
T? safeParse<T>(dynamic value, String fieldName, {T? defaultValue}) {
  if (value == null) return defaultValue;
  if (value is T) return value;
  if (T == String) return value.toString() as T;
  if (T == int) {
    if (value is double) return value.toInt() as T;
    if (value is String) return int.tryParse(value) as T? ?? defaultValue;
  }
  if (T == double) {
    if (value is int) return value.toDouble() as T;
    if (value is String) return double.tryParse(value) as T? ?? defaultValue;
  }
  if (T == bool) {
    if (value is String) return (value == 'true' || value == '1') as T;
    if (value is int) return (value != 0) as T;
  }
  return defaultValue;
}

/// Parses an ISO-8601 timestamp, returning [defaultValue] when absent or bad.
DateTime? parseDateTime(
  dynamic value,
  String fieldName, {
  DateTime? defaultValue,
}) {
  final text = safeParse<String>(value, fieldName);
  if (text == null) return defaultValue;
  return DateTime.tryParse(text) ?? defaultValue;
}

/// Safely extracts a `List<Map<String, dynamic>>` from a JSON value.
List<Map<String, dynamic>> safeMapList(dynamic value) {
  if (value is! List) return const [];
  return value.whereType<Map<String, dynamic>>().toList();
}
