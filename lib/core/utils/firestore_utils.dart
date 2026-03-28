import 'package:cloud_firestore/cloud_firestore.dart';

/// Utilities for robustly handling Firestore data types.
class FirestoreUtils {
  /// Safely converts a dynamic Firestore field to a DateTime.
  /// Handles:
  /// - null -> null
  /// - Timestamp -> DateTime
  /// - int (milliseconds) -> DateTime
  /// - String (ISO 8601) -> DateTime
  static DateTime? tryParseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// Parses a DateTime with a fallback.
  static DateTime parseDateTime(dynamic value, {DateTime? fallback}) {
    return tryParseDateTime(value) ?? fallback ?? DateTime.now();
  }
}
