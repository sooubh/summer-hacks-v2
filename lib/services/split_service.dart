import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:student_fin_os/core/utils/firestore_codec.dart';
import 'package:student_fin_os/models/finance_enums.dart';
import 'package:student_fin_os/models/split_expense.dart';
import 'package:student_fin_os/models/split_group.dart';

class SplitService {
  SplitService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _groups(String userId) {
    return _firestore.collection('users').doc(userId).collection('split_groups');
  }

  CollectionReference<Map<String, dynamic>> _groupExpenses(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('split_expenses');
  }

  Stream<List<SplitGroup>> watchGroups(String userId) {
    return _groups(userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
      return snapshot.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
            return SplitGroup.fromMap(doc.id, doc.data());
          })
          .toList();
    });
  }

  Future<void> createGroup(String userId, SplitGroup group) async {
    await _groups(userId).doc(group.id).set(group.toMap(), SetOptions(merge: true));
  }

  Stream<List<SplitExpense>> watchGroupExpenses({
    required String userId,
    required String groupId,
  }) {
    return _groupExpenses(userId)
        .where('groupId', isEqualTo: groupId)
        .orderBy('expenseAt', descending: true)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
      return snapshot.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
            return SplitExpense.fromMap(doc.id, doc.data());
          })
          .toList();
    });
  }

  Future<void> addGroupExpense(String userId, SplitExpense expense) async {
    final WriteBatch batch = _firestore.batch();
    final DocumentReference<Map<String, dynamic>> expenseRef =
        _groupExpenses(userId).doc(expense.id);
    final DocumentReference<Map<String, dynamic>> groupRef =
        _groups(userId).doc(expense.groupId);

    batch.set(expenseRef, expense.toMap(), SetOptions(merge: true));
    batch.update(groupRef, <String, dynamic>{
      'updatedAt': FirestoreCodec.writeDateTime(DateTime.now().toUtc()),
    });

    await batch.commit();
  }

  Future<void> markSettled({
    required String userId,
    required String expenseId,
  }) async {
    await _groupExpenses(userId).doc(expenseId).update(<String, dynamic>{
      'status': SplitStatus.settled.name,
      'updatedAt': FirestoreCodec.writeDateTime(DateTime.now().toUtc()),
    });
  }

  Map<String, double> netBalances(
    List<SplitExpense> expenses,
    List<String> memberIds,
  ) {
    final Map<String, double> totals = <String, double>{
      for (final String id in memberIds) id: 0,
    };

    for (final SplitExpense expense in expenses) {
      totals.update(expense.paidBy, (double value) => value + expense.totalAmount,
          ifAbsent: () => expense.totalAmount);

      expense.owedBy.forEach((String memberId, double amount) {
        totals.update(memberId, (double value) => value - amount,
            ifAbsent: () => -amount);
      });
    }

    return totals;
  }
}
