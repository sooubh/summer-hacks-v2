import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:student_fin_os/models/account.dart';
import 'package:student_fin_os/models/finance_enums.dart';
import 'package:student_fin_os/models/finance_transaction.dart';
import 'package:uuid/uuid.dart';

class MockBankService {
  MockBankService(this._firestore, this._uuid);

  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  Future<void> seedStarterData(String userId) async {
    final CollectionReference<Map<String, dynamic>> accountsRef =
        _firestore.collection('users').doc(userId).collection('accounts');

    final QuerySnapshot<Map<String, dynamic>> existing = await accountsRef.get();
    if (existing.docs.isNotEmpty) {
      return;
    }

    final DateTime now = DateTime.now().toUtc();

    final List<Account> accounts = <Account>[
      Account(
        id: _uuid.v4(),
        userId: userId,
        name: 'SBI Savings',
        type: AccountType.bank,
        provider: 'SBI',
        balance: 4200,
        createdAt: now,
        updatedAt: now,
        icon: 'account_balance',
      ),
      Account(
        id: _uuid.v4(),
        userId: userId,
        name: 'PhonePe Wallet',
        type: AccountType.upi,
        provider: 'PhonePe',
        balance: 1300,
        createdAt: now,
        updatedAt: now,
        icon: 'smartphone',
      ),
      Account(
        id: _uuid.v4(),
        userId: userId,
        name: 'Cash in Hand',
        type: AccountType.cash,
        provider: 'Wallet',
        balance: 650,
        createdAt: now,
        updatedAt: now,
        icon: 'payments',
      ),
    ];

    final WriteBatch batch = _firestore.batch();
    for (final Account account in accounts) {
      batch.set(accountsRef.doc(account.id), account.toMap());
    }

    final CollectionReference<Map<String, dynamic>> txRef =
        _firestore.collection('users').doc(userId).collection('transactions');

    final List<FinanceTransaction> transactions = <FinanceTransaction>[
      FinanceTransaction(
        id: _uuid.v4(),
        userId: userId,
        accountId: accounts[0].id,
        title: 'Monthly stipend',
        amount: 5500,
        type: TransactionType.income,
        category: 'stipend',
        transactionAt: now.subtract(const Duration(days: 12)),
        createdAt: now,
        updatedAt: now,
        tags: const <String>['income'],
      ),
      FinanceTransaction(
        id: _uuid.v4(),
        userId: userId,
        accountId: accounts[1].id,
        title: 'Mess bill',
        amount: 1200,
        type: TransactionType.expense,
        category: 'food',
        transactionAt: now.subtract(const Duration(days: 9)),
        createdAt: now,
        updatedAt: now,
        tags: const <String>['essential'],
      ),
      FinanceTransaction(
        id: _uuid.v4(),
        userId: userId,
        accountId: accounts[2].id,
        title: 'Auto rickshaw',
        amount: 180,
        type: TransactionType.expense,
        category: 'travel',
        transactionAt: now.subtract(const Duration(days: 5)),
        createdAt: now,
        updatedAt: now,
        tags: const <String>['daily'],
      ),
      FinanceTransaction(
        id: _uuid.v4(),
        userId: userId,
        accountId: accounts[1].id,
        title: 'Freelance payout',
        amount: 3000,
        type: TransactionType.income,
        category: 'freelance',
        transactionAt: now.subtract(const Duration(days: 3)),
        createdAt: now,
        updatedAt: now,
        tags: const <String>['side-income'],
      ),
    ];

    for (final FinanceTransaction tx in transactions) {
      batch.set(txRef.doc(tx.id), tx.toMap());
    }

    await batch.commit();
  }
}
