import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  NotificationService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _reminders(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notification_preferences');
  }

  Future<void> upsertDailyReminder({
    required String userId,
    required bool enabled,
    required String localTime,
  }) async {
    await _reminders(userId).doc('daily_spend').set(<String, dynamic>{
      'enabled': enabled,
      'localTime': localTime,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> upsertBudgetAlert({
    required String userId,
    required bool enabled,
    required double monthlyLimit,
  }) async {
    await _reminders(userId).doc('budget_alert').set(<String, dynamic>{
      'enabled': enabled,
      'monthlyLimit': monthlyLimit,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<Map<String, dynamic>> watchPreferences(String userId) {
    return _reminders(userId).snapshots().map((QuerySnapshot<Map<String, dynamic>> snapshot) {
      final Map<String, dynamic> result = <String, dynamic>{};
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snapshot.docs) {
        result[doc.id] = doc.data();
      }
      return result;
    });
  }
}
