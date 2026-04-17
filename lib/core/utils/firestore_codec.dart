import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreCodec {
  static DateTime readDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value)?.toUtc() ?? DateTime.now().toUtc();
    }
    return DateTime.now().toUtc();
  }

  static Timestamp writeDateTime(DateTime value) {
    return Timestamp.fromDate(value.toUtc());
  }

  static T readEnum<T extends Enum>(List<T> values, String? raw, T fallback) {
    if (raw == null) {
      return fallback;
    }
    for (final value in values) {
      if (value.name == raw) {
        return value;
      }
    }
    return fallback;
  }

  static String writeEnum(Enum value) {
    return value.name;
  }
}
