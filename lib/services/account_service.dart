import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:student_fin_os/core/utils/firestore_codec.dart';
import 'package:student_fin_os/models/account.dart';

class AccountService {
  AccountService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _accountsCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('accounts');
  }

  Stream<List<Account>> watchAccounts(String userId) {
    return _accountsCollection(userId)
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
  }

  Future<void> upsertAccount(Account account) async {
    await _accountsCollection(account.userId)
        .doc(account.id)
        .set(account.toMap(), SetOptions(merge: true));
  }

  Future<void> archiveAccount({
    required String userId,
    required String accountId,
  }) async {
    await _accountsCollection(userId).doc(accountId).update(<String, dynamic>{
      'isActive': false,
      'updatedAt': FirestoreCodec.writeDateTime(DateTime.now().toUtc()),
    });
  }

  Future<double> getUnifiedBalance(String userId) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await _accountsCollection(userId).where('isActive', isEqualTo: true).get();
    double total = 0;

    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snapshot.docs) {
      total += (doc.data()['balance'] as num?)?.toDouble() ?? 0;
    }

    return total;
  }
}
