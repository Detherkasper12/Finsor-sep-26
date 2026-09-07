/// Safe JSON parsing to avoid "type 'int' is not a subtype of type 'String?'" and similar.
/// Use for any value that may come from JSON (Supabase, backup, API).

String? safeString(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  return value.toString();
}

String safeStringOr(dynamic value, String fallback) => safeString(value) ?? fallback;

DateTime? safeDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  final s = safeString(value);
  if (s == null || s.isEmpty) return null;
  return DateTime.tryParse(s);
}

int? safeInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double? safeDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
