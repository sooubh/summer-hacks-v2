import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:student_fin_os/models/account.dart';
import 'package:student_fin_os/models/account_aggregation_snapshot.dart';
import 'package:student_fin_os/models/finance_transaction.dart';

class AggregatorService {
  AggregatorService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _accounts(String userId) {
    return _firestore.collection('users').doc(userId).collection('accounts');
  }

  CollectionReference<Map<String, dynamic>> _transactions(String userId) {
    return _firestore.collection('users').doc(userId).collection('transactions');
  }

  Stream<AccountAggregationSnapshot> watchUnifiedSnapshot(
    String userId, {
    int transactionLimit = 150,
  }) {
    final Stream<List<Account>> accountsStream = _accounts(userId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
      return snapshot.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
            return Account.fromMap(doc.id, doc.data());
          })
          .toList();
    });

    final Stream<List<FinanceTransaction>> transactionsStream = _transactions(userId)
        .orderBy('transactionAt', descending: true)
        .limit(transactionLimit)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
      return snapshot.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
            return FinanceTransaction.fromMap(doc.id, doc.data());
          })
          .toList();
    });

    return Stream<AccountAggregationSnapshot>.multi((
      MultiStreamController<AccountAggregationSnapshot> controller,
    ) {
      List<Account> accounts = const <Account>[];
      List<FinanceTransaction> transactions = const <FinanceTransaction>[];

      void emit() {
        controller.add(
          AccountAggregationSnapshot.fromData(
            accounts: accounts,
            transactions: transactions,
          ),
        );
      }

      final StreamSubscription<List<Account>> accountSub =
          accountsStream.listen((List<Account> nextAccounts) {
        accounts = nextAccounts;
        emit();
      }, onError: controller.addError);

      final StreamSubscription<List<FinanceTransaction>> txSub =
          transactionsStream.listen((List<FinanceTransaction> nextTransactions) {
        transactions = nextTransactions;
        emit();
      }, onError: controller.addError);

      controller.onCancel = () async {
        await accountSub.cancel();
        await txSub.cancel();
      };
    });
  }
}
