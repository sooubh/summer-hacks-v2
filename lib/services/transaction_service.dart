import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:student_fin_os/core/utils/firestore_codec.dart';
import 'package:student_fin_os/models/finance_enums.dart';
import 'package:student_fin_os/models/finance_transaction.dart';

class TransactionService {
  TransactionService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _transactions(String userId) {
    return _firestore.collection('users').doc(userId).collection('transactions');
  }

  Stream<List<FinanceTransaction>> watchTransactions(
    String userId, {
    int limit = 60,
  }) {
    return _transactions(userId)
        .orderBy('transactionAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
      return snapshot.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
            return FinanceTransaction.fromMap(doc.id, doc.data());
          })
          .toList();
    });
  }

  Future<void> createTransaction(FinanceTransaction tx) async {
    final DocumentReference<Map<String, dynamic>> accountRef = _firestore
        .collection('users')
        .doc(tx.userId)
        .collection('accounts')
        .doc(tx.accountId);

    final DocumentReference<Map<String, dynamic>> txRef =
        _transactions(tx.userId).doc(tx.id);

    await _firestore.runTransaction((Transaction transaction) async {
      final DocumentSnapshot<Map<String, dynamic>> accountSnapshot =
          await transaction.get(accountRef);
      if (!accountSnapshot.exists) {
        throw StateError('Account not found for transaction.');
      }

      final double currentBalance =
          (accountSnapshot.data()?['balance'] as num?)?.toDouble() ?? 0;
      final double nextBalance = currentBalance + _balanceDelta(tx);

      transaction.set(txRef, tx.toMap());
      transaction.update(accountRef, <String, dynamic>{
        'balance': nextBalance,
        'transactionIds': FieldValue.arrayUnion(<String>[tx.id]),
        'updatedAt': FirestoreCodec.writeDateTime(DateTime.now().toUtc()),
      });
    });
  }

  Future<void> deleteTransaction(FinanceTransaction tx) async {
    final DocumentReference<Map<String, dynamic>> accountRef = _firestore
        .collection('users')
        .doc(tx.userId)
        .collection('accounts')
        .doc(tx.accountId);

    final DocumentReference<Map<String, dynamic>> txRef =
        _transactions(tx.userId).doc(tx.id);

    await _firestore.runTransaction((Transaction transaction) async {
      final DocumentSnapshot<Map<String, dynamic>> accountSnapshot =
          await transaction.get(accountRef);
      if (!accountSnapshot.exists) {
        throw StateError('Account not found for transaction deletion.');
      }

      final double currentBalance =
          (accountSnapshot.data()?['balance'] as num?)?.toDouble() ?? 0;
      final double nextBalance = currentBalance - _balanceDelta(tx);

      transaction.delete(txRef);
      transaction.update(accountRef, <String, dynamic>{
        'balance': nextBalance,
        'transactionIds': FieldValue.arrayRemove(<String>[tx.id]),
        'updatedAt': FirestoreCodec.writeDateTime(DateTime.now().toUtc()),
      });
    });
  }

  Future<void> overrideTransactionCategory({
    required String userId,
    required String transactionId,
    required String category,
  }) async {
    await _transactions(userId).doc(transactionId).update(<String, dynamic>{
      'category': category,
      'isCategoryOverridden': true,
      'updatedAt': FirestoreCodec.writeDateTime(DateTime.now().toUtc()),
    });
  }

  double _balanceDelta(FinanceTransaction tx) {
    switch (tx.type) {
      case TransactionType.income:
        return tx.amount;
      case TransactionType.expense:
        return -tx.amount;
      case TransactionType.transfer:
        return 0;
      case TransactionType.splitSettlement:
        return -tx.amount;
    }
  }
}
