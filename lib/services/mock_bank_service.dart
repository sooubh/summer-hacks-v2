import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:student_fin_os/data/mock/mock_seed.dart';
import 'package:student_fin_os/models/account.dart';
import 'package:student_fin_os/models/finance_enums.dart';
import 'package:student_fin_os/models/finance_transaction.dart';
import 'package:student_fin_os/models/savings_goal.dart';
import 'package:uuid/uuid.dart';

class MockBankService {
  MockBankService(this._firestore, this._uuid);

  final FirebaseFirestore _firestore;
  final Uuid _uuid;
  static const int _seedVersion = 2;

  Future<void> seedStarterData(String userId) async {
    if (userId.isEmpty) {
      return;
    }

    final DocumentReference<Map<String, dynamic>> userRef =
        _firestore.collection('users').doc(userId);
    final CollectionReference<Map<String, dynamic>> accountsRef =
        userRef.collection('accounts');
    final CollectionReference<Map<String, dynamic>> txRef =
        userRef.collection('transactions');
    final CollectionReference<Map<String, dynamic>> goalsRef =
        userRef.collection('savings_goals');
    final CollectionReference<Map<String, dynamic>> preferencesRef =
        userRef.collection('notification_preferences');

    final DocumentSnapshot<Map<String, dynamic>> userSnapshot = await userRef.get();
    final int seedVersion =
        (userSnapshot.data()?['dummyBankSeedVersion'] as num?)?.toInt() ?? 0;

    final QuerySnapshot<Map<String, dynamic>> existingAccounts =
        await accountsRef.orderBy('createdAt', descending: false).get();
    final QuerySnapshot<Map<String, dynamic>> existingTransactions =
        await txRef.limit(1).get();
    final QuerySnapshot<Map<String, dynamic>> existingGoals =
        await goalsRef.limit(1).get();
    final QuerySnapshot<Map<String, dynamic>> existingPreferences =
        await preferencesRef.limit(1).get();

    final bool shouldSeedAccounts = existingAccounts.docs.isEmpty;
    final bool shouldSeedTransactions = existingTransactions.docs.isEmpty;
    final bool shouldSeedGoals = existingGoals.docs.isEmpty;
    final bool shouldSeedPreferences = existingPreferences.docs.isEmpty;

    if (seedVersion >= _seedVersion &&
        !shouldSeedAccounts &&
        !shouldSeedTransactions &&
        !shouldSeedGoals &&
        !shouldSeedPreferences) {
      return;
    }

    final DateTime now = DateTime.now().toUtc();
    final MockSeed seed = await _loadSeed();

    final List<Account> accounts = shouldSeedAccounts
        ? _buildStarterAccounts(
            userId: userId,
            now: now,
            seedAccounts: seed.accounts,
          )
        : existingAccounts.docs
            .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
                return Account.fromMap(doc.id, doc.data());
              })
            .toList();

    final List<FinanceTransaction> transactions = shouldSeedTransactions
        ? _buildStarterTransactions(
            userId: userId,
            now: now,
            accounts: accounts,
            seedTransactions: seed.transactions,
          )
        : const <FinanceTransaction>[];

    final Map<String, List<String>> transactionIdsByAccount =
        <String, List<String>>{};
    for (final FinanceTransaction tx in transactions) {
      transactionIdsByAccount
          .putIfAbsent(tx.accountId, () => <String>[])
          .add(tx.id);
    }

    final List<SavingsGoal> goals = shouldSeedGoals
        ? _buildStarterGoals(
            userId: userId,
            now: now,
            seedGoals: seed.savingsGoals,
          )
        : const <SavingsGoal>[];

    final WriteBatch batch = _firestore.batch();

    if (shouldSeedAccounts) {
      for (final Account account in accounts) {
        final List<String> accountTransactionIds =
            transactionIdsByAccount[account.id] ?? const <String>[];
        batch.set(
          accountsRef.doc(account.id),
          Account(
            id: account.id,
            userId: account.userId,
            name: account.name,
            type: account.type,
            provider: account.provider,
            balance: account.balance,
            isActive: account.isActive,
            icon: account.icon,
            transactionIds: accountTransactionIds,
            createdAt: account.createdAt,
            updatedAt: account.updatedAt,
          ).toMap(),
        );
      }
    }

    if (shouldSeedTransactions) {
      for (final FinanceTransaction tx in transactions) {
        batch.set(txRef.doc(tx.id), tx.toMap());
      }
    }

    if (!shouldSeedAccounts && shouldSeedTransactions) {
      for (final MapEntry<String, List<String>> entry
          in transactionIdsByAccount.entries) {
        batch.update(accountsRef.doc(entry.key), <String, dynamic>{
          'transactionIds': FieldValue.arrayUnion(entry.value),
          'updatedAt': Timestamp.fromDate(now),
        });
      }
    }

    for (final SavingsGoal goal in goals) {
      batch.set(goalsRef.doc(goal.id), goal.toMap(), SetOptions(merge: true));
    }

    if (shouldSeedPreferences) {
      batch.set(preferencesRef.doc('daily_spend'), <String, dynamic>{
        'enabled': true,
        'localTime': '20:00',
        'updatedAt': Timestamp.fromDate(now),
      }, SetOptions(merge: true));

      batch.set(preferencesRef.doc('budget_alert'), <String, dynamic>{
        'enabled': true,
        'monthlyLimit': 8000,
        'updatedAt': Timestamp.fromDate(now),
      }, SetOptions(merge: true));
    }

    batch.set(userRef, <String, dynamic>{
      'dummyBankSeedVersion': _seedVersion,
      'dummyBankSeededAt': Timestamp.fromDate(now),
      'updatedAt': FieldValue.serverTimestamp(),
      'defaultCurrency': userSnapshot.data()?['defaultCurrency'] ?? 'INR',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Future<MockSeed> _loadSeed() async {
    try {
      return await MockSeedLoader.loadFromAsset();
    } catch (_) {
      return const MockSeed(
        accounts: <Map<String, dynamic>>[
          <String, dynamic>{
            'name': 'SBI Savings',
            'type': 'bank',
            'provider': 'SBI',
            'balance': 4200,
          },
          <String, dynamic>{
            'name': 'PhonePe Wallet',
            'type': 'upi',
            'provider': 'PhonePe',
            'balance': 1300,
          },
          <String, dynamic>{
            'name': 'Cash in Hand',
            'type': 'cash',
            'provider': 'Wallet',
            'balance': 650,
          },
        ],
        transactions: <Map<String, dynamic>>[
          <String, dynamic>{
            'title': 'Monthly stipend',
            'amount': 5500,
            'type': 'income',
            'category': 'stipend',
            'source': 'bank transfer',
            'channel': 'bank_transfer',
          },
          <String, dynamic>{
            'title': 'Mess bill',
            'amount': 1200,
            'type': 'expense',
            'category': 'food',
            'source': 'Google Pay',
            'channel': 'upi',
          },
          <String, dynamic>{
            'title': 'Freelance payout',
            'amount': 3000,
            'type': 'income',
            'category': 'freelance',
            'source': 'bank transfer',
            'channel': 'bank_transfer',
          },
          <String, dynamic>{
            'title': 'Groceries - Dmart',
            'amount': 980,
            'type': 'expense',
            'category': 'grocery',
            'source': 'PhonePe',
            'channel': 'upi',
          },
          <String, dynamic>{
            'title': 'Metro Recharge',
            'amount': 450,
            'type': 'expense',
            'category': 'travel',
            'source': 'Paytm',
            'channel': 'upi',
          },
          <String, dynamic>{
            'title': 'Tea and Snacks',
            'amount': 120,
            'type': 'expense',
            'category': 'food',
            'source': 'Cash',
            'channel': 'cash',
          },
          <String, dynamic>{
            'title': 'Online Shopping',
            'amount': 1890,
            'type': 'expense',
            'category': 'shopping',
            'source': 'Amazon Pay',
            'channel': 'upi',
          },
          <String, dynamic>{
            'title': 'Pharmacy',
            'amount': 420,
            'type': 'expense',
            'category': 'health',
            'source': 'BHIM UPI',
            'channel': 'upi',
          },
          <String, dynamic>{
            'title': 'Fuel',
            'amount': 850,
            'type': 'expense',
            'category': 'travel',
            'source': 'Cash',
            'channel': 'cash',
          },
          <String, dynamic>{
            'title': 'Laptop Accessory',
            'amount': 1299,
            'type': 'expense',
            'category': 'shopping',
            'source': 'HDFC Debit Card',
            'channel': 'card',
          },
        ],
        savingsGoals: <Map<String, dynamic>>[
          <String, dynamic>{
            'title': 'Emergency fund',
            'targetAmount': 10000,
            'savedAmount': 2500,
            'deadlineDays': 120,
          },
        ],
      );
    }
  }

  List<Account> _buildStarterAccounts({
    required String userId,
    required DateTime now,
    required List<Map<String, dynamic>> seedAccounts,
  }) {
    final List<Account> accounts = <Account>[];

    for (final Map<String, dynamic> raw in seedAccounts) {
      final String name = _readString(raw['name'], fallback: 'Student Account');
      final AccountType type = _parseAccountType(raw['type']);
      final double balance = _readAmount(raw['balance']);
      final String provider = _readString(raw['provider'], fallback: 'Bank');

      accounts.add(
        Account(
          id: _uuid.v4(),
          userId: userId,
          name: name,
          type: type,
          provider: provider,
          balance: balance,
          createdAt: now,
          updatedAt: now,
          icon: _iconForAccountType(type),
        ),
      );
    }

    if (accounts.isNotEmpty) {
      return accounts;
    }

    return <Account>[
      Account(
        id: _uuid.v4(),
        userId: userId,
        name: 'SBI Savings',
        type: AccountType.bank,
        provider: 'SBI',
        balance: 4200,
        createdAt: now,
        updatedAt: now,
        icon: _iconForAccountType(AccountType.bank),
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
        icon: _iconForAccountType(AccountType.upi),
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
        icon: _iconForAccountType(AccountType.cash),
      ),
    ];
  }

  List<FinanceTransaction> _buildStarterTransactions({
    required String userId,
    required DateTime now,
    required List<Account> accounts,
    required List<Map<String, dynamic>> seedTransactions,
  }) {
    if (accounts.isEmpty) {
      return const <FinanceTransaction>[];
    }

    final List<FinanceTransaction> transactions = <FinanceTransaction>[];

    for (int index = 0; index < seedTransactions.length; index += 1) {
      final Map<String, dynamic> raw = seedTransactions[index];
      final TransactionType type = _parseTransactionType(raw['type']);
      final double amount = _readAmount(raw['amount']);
      if (amount <= 0) {
        continue;
      }

      final String category = _readString(raw['category'], fallback: 'misc');
      final String title = _readString(raw['title'], fallback: 'Starter transaction');
      final String source = _normalizeSource(raw['source']);
      final String channel = _normalizeChannel(raw['channel'] ?? raw['source']);

      final String accountId = _pickAccountId(
        accounts: accounts,
        type: type,
        channel: channel,
      );

      transactions.add(
        FinanceTransaction(
          id: _uuid.v4(),
          userId: userId,
          accountId: accountId,
          title: title,
          amount: amount,
          type: type,
          category: category,
          transactionAt: now.subtract(Duration(days: 3 * (index + 1))),
          createdAt: now,
          updatedAt: now,
          tags: <String>[if (type == TransactionType.income) 'income' else 'expense'],
          source: source,
          channel: channel,
        ),
      );
    }

    return transactions;
  }

  List<SavingsGoal> _buildStarterGoals({
    required String userId,
    required DateTime now,
    required List<Map<String, dynamic>> seedGoals,
  }) {
    final List<SavingsGoal> goals = <SavingsGoal>[];

    for (int index = 0; index < seedGoals.length; index += 1) {
      final Map<String, dynamic> raw = seedGoals[index];
      final double targetAmount = _readAmount(raw['targetAmount']);
      if (targetAmount <= 0) {
        continue;
      }

      final double savedAmount = _readAmount(raw['savedAmount']);
      final int deadlineDays = _readInt(raw['deadlineDays'], fallback: 120).clamp(30, 730);

      goals.add(
        SavingsGoal(
          id: _uuid.v4(),
          userId: userId,
          title: _readString(raw['title'], fallback: 'Emergency fund'),
          targetAmount: targetAmount,
          savedAmount: savedAmount.clamp(0, targetAmount).toDouble(),
          deadline: now.add(Duration(days: deadlineDays)),
          status: savedAmount >= targetAmount ? GoalStatus.achieved : GoalStatus.active,
          priority: index + 1,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    return goals;
  }

  String _pickAccountId({
    required List<Account> accounts,
    required TransactionType type,
    required String channel,
  }) {
    AccountType preferredType = type == TransactionType.income
        ? AccountType.bank
        : AccountType.upi;

    if (channel == 'cash') {
      preferredType = AccountType.cash;
    } else if (channel == 'upi') {
      preferredType = AccountType.upi;
    } else if (channel == 'bank_transfer' || channel == 'card') {
      preferredType = AccountType.bank;
    }

    for (final Account account in accounts) {
      if (account.type == preferredType) {
        return account.id;
      }
    }

    return accounts.first.id;
  }

  AccountType _parseAccountType(dynamic value) {
    final String normalized = value?.toString().trim().toLowerCase() ?? '';
    switch (normalized) {
      case 'bank':
        return AccountType.bank;
      case 'upi':
      case 'wallet':
        return AccountType.upi;
      case 'cash':
        return AccountType.cash;
      default:
        return AccountType.cash;
    }
  }

  TransactionType _parseTransactionType(dynamic value) {
    final String normalized = value?.toString().trim().toLowerCase() ?? '';
    switch (normalized) {
      case 'income':
        return TransactionType.income;
      case 'expense':
        return TransactionType.expense;
      case 'transfer':
        return TransactionType.transfer;
      case 'splitsettlement':
      case 'split_settlement':
        return TransactionType.splitSettlement;
      default:
        return TransactionType.expense;
    }
  }

  String _normalizeSource(dynamic value) {
    final String normalized = value?.toString().trim().toLowerCase() ?? '';
    if (normalized.isEmpty) {
      return 'manual';
    }

    if (normalized == 'qr' || normalized == 'manual') {
      return normalized;
    }

    return normalized.replaceAll('_', ' ');
  }

  String _normalizeChannel(dynamic value) {
    final String normalized = value?.toString().trim().toLowerCase() ?? '';
    if (normalized.contains('cash')) {
      return 'cash';
    }
    if (normalized.contains('card') ||
        normalized.contains('credit') ||
        normalized.contains('debit')) {
      return 'card';
    }
    if (normalized.contains('bank') || normalized.contains('transfer')) {
      return 'bank_transfer';
    }

    if (normalized == 'cash' ||
        normalized == 'card' ||
        normalized == 'bank_transfer' ||
        normalized == 'upi') {
      return normalized;
    }

    if (normalized.contains('phonepe') ||
        normalized.contains('phone pe') ||
        normalized.contains('gpay') ||
        normalized.contains('google') ||
        normalized.contains('paytm') ||
        normalized.contains('amazon pay') ||
        normalized.contains('bhim') ||
        normalized.contains('cred') ||
        normalized.contains('freecharge') ||
        normalized.contains('mobikwik')) {
      return 'upi';
    }

    return 'cash';
  }

  String _iconForAccountType(AccountType type) {
    switch (type) {
      case AccountType.bank:
        return 'account_balance';
      case AccountType.upi:
        return 'smartphone';
      case AccountType.cash:
        return 'payments';
    }
  }

  String _readString(dynamic value, {required String fallback}) {
    final String text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  double _readAmount(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _readInt(dynamic value, {required int fallback}) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
