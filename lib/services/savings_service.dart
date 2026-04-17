import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:student_fin_os/models/finance_enums.dart';
import 'package:student_fin_os/models/savings_goal.dart';

class SavingsService {
  SavingsService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _goals(String userId) {
    return _firestore.collection('users').doc(userId).collection('savings_goals');
  }

  Stream<List<SavingsGoal>> watchGoals(String userId) {
    return _goals(userId)
        .orderBy('priority', descending: false)
        .orderBy('deadline', descending: false)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
      return snapshot.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
            return SavingsGoal.fromMap(doc.id, doc.data());
          })
          .toList();
    });
  }

  Future<void> upsertGoal(SavingsGoal goal) async {
    await _goals(goal.userId)
        .doc(goal.id)
        .set(goal.toMap(), SetOptions(merge: true));
  }

  Future<void> contributeToGoal({
    required String userId,
    required String goalId,
    required double amount,
  }) async {
    final DocumentReference<Map<String, dynamic>> goalRef =
        _goals(userId).doc(goalId);

    await _firestore.runTransaction((Transaction tx) async {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await tx.get(goalRef);
      if (!snapshot.exists) {
        throw StateError('Savings goal not found.');
      }

      final SavingsGoal goal = SavingsGoal.fromMap(goalId, snapshot.data()!);
      final double updatedSavedAmount = goal.savedAmount + amount;
      final GoalStatus status = updatedSavedAmount >= goal.targetAmount
          ? GoalStatus.achieved
          : GoalStatus.active;

      tx.update(goalRef, <String, dynamic>{
        'savedAmount': updatedSavedAmount,
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  double recommendedMonthlyContribution(SavingsGoal goal) {
    final DateTime now = DateTime.now().toUtc();
    final int monthsLeft =
        (goal.deadline.difference(now).inDays / 30).ceil().clamp(1, 120);
    final double pending = (goal.targetAmount - goal.savedAmount).clamp(0, 1e12);
    return pending / monthsLeft;
  }

  double calculateSafeToSpend({
    required double totalBalance,
    required double weeklyExpectedSpend,
    required double monthlyGoalContribution,
  }) {
    final double reserve = weeklyExpectedSpend * 1.4;
    final double safe = totalBalance - reserve - monthlyGoalContribution;
    return safe < 0 ? 0 : safe;
  }
}
