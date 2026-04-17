import 'dart:math';

import 'package:student_fin_os/models/account.dart';
import 'package:student_fin_os/models/finance_enums.dart';
import 'package:student_fin_os/models/finance_transaction.dart';
import 'package:student_fin_os/services/account_service.dart';
import 'package:student_fin_os/services/transaction_service.dart';
import 'package:uuid/uuid.dart';

class SimulationService {
  SimulationService({
    required AccountService accountService,
    required TransactionService transactionService,
    required Uuid uuid,
  })  : _accountService = accountService,
        _transactionService = transactionService,
        _uuid = uuid;

  final AccountService _accountService;
  final TransactionService _transactionService;
  final Uuid _uuid;

  final Random _random = Random();

  static const List<String> categoryCatalog = <String>[
    'food',
    'travel',
    'rent',
    'shopping',
    'utilities',
    'entertainment',
    'education',
    'health',
    'freelance',
    'stipend',
    'misc',
  ];

  Future<List<Account>> seedVirtualAccountsIfEmpty({
    required String userId,
    required List<Account> existingAccounts,
  }) async {
    if (existingAccounts.isNotEmpty) {
      return existingAccounts;
    }

    final DateTime now = DateTime.now().toUtc();
    final List<Account> simulated = <Account>[
      Account(
        id: _uuid.v4(),
        userId: userId,
        name: 'SBI Savings',
        type: AccountType.bank,
        provider: 'SBI',
        balance: 9500,
        icon: 'account_balance',
        createdAt: now,
        updatedAt: now,
      ),
      Account(
        id: _uuid.v4(),
        userId: userId,
        name: 'HDFC Student',
        type: AccountType.bank,
        provider: 'HDFC',
        balance: 4200,
        icon: 'savings',
        createdAt: now,
        updatedAt: now,
      ),
      Account(
        id: _uuid.v4(),
        userId: userId,
        name: 'GPay Wallet',
        type: AccountType.upi,
        provider: 'GPay',
        balance: 1600,
        icon: 'smartphone',
        createdAt: now,
        updatedAt: now,
      ),
      Account(
        id: _uuid.v4(),
        userId: userId,
        name: 'Cash Wallet',
        type: AccountType.cash,
        provider: 'Cash',
        balance: 700,
        icon: 'payments',
        createdAt: now,
        updatedAt: now,
      ),
    ];

    for (final Account account in simulated) {
      await _accountService.upsertAccount(account);
    }
    return simulated;
  }

  Future<void> simulateCredit({
    required String userId,
    required String accountId,
    String title = 'Pocket money credited',
    double amount = 2500,
  }) async {
    await _createSimulatedTransaction(
      userId: userId,
      accountId: accountId,
      title: title,
      amount: amount,
      type: TransactionType.income,
      source: 'simulation',
      channel: 'bank_transfer',
    );
  }

  Future<void> simulateDebit({
    required String userId,
    required String accountId,
    String title = 'General expense',
    double amount = 420,
  }) async {
    await _createSimulatedTransaction(
      userId: userId,
      accountId: accountId,
      title: title,
      amount: amount,
      type: TransactionType.expense,
      source: 'simulation',
      channel: 'card',
    );
  }

  Future<void> simulateUpiPayment({
    required String userId,
    required String accountId,
    String title = 'UPI payment',
    double amount = 240,
  }) async {
    await _createSimulatedTransaction(
      userId: userId,
      accountId: accountId,
      title: title,
      amount: amount,
      type: TransactionType.expense,
      source: 'simulation',
      channel: 'upi',
      tags: const <String>['upi'],
    );
  }

  Future<void> generateMockTransactions({
    required String userId,
    required List<Account> accounts,
    int count = 6,
  }) async {
    if (accounts.isEmpty) {
      return;
    }

    final List<String> incomes = <String>[
      'Monthly stipend',
      'Freelance payment',
      'Pocket money',
      'Scholarship credit',
    ];

    final List<String> expenses = <String>[
      'Hostel mess',
      'Metro recharge',
      'Room rent share',
      'Online order',
      'Movie night',
      'Pharmacy purchase',
      'Internet bill',
    ];

    for (int i = 0; i < count; i++) {
      final bool income = _random.nextDouble() > 0.65;
      final Account account = accounts[_random.nextInt(accounts.length)];
      final String title = income
          ? incomes[_random.nextInt(incomes.length)]
          : expenses[_random.nextInt(expenses.length)];
      final double amount = income
          ? (1000 + _random.nextInt(4500)).toDouble()
          : (120 + _random.nextInt(2200)).toDouble();

      await _createSimulatedTransaction(
        userId: userId,
        accountId: account.id,
        title: title,
        amount: amount,
        type: income ? TransactionType.income : TransactionType.expense,
        source: 'simulation',
        channel: account.type == AccountType.upi ? 'upi' : 'cash',
      );
    }
  }

  String suggestCategory({
    required String title,
    required TransactionType type,
    List<String> tags = const <String>[],
  }) {
    if (type == TransactionType.income) {
      if (_contains(title, const <String>['stipend', 'scholarship'])) {
        return 'stipend';
      }
      if (_contains(title, const <String>['freelance', 'project'])) {
        return 'freelance';
      }
      return 'misc';
    }

    if (_contains(title, const <String>['food', 'mess', 'cafe', 'swiggy', 'zomato'])) {
      return 'food';
    }
    if (_contains(title, const <String>['metro', 'uber', 'bus', 'travel', 'auto'])) {
      return 'travel';
    }
    if (_contains(title, const <String>['rent', 'hostel'])) {
      return 'rent';
    }
    if (_contains(title, const <String>['movie', 'netflix', 'entertainment'])) {
      return 'entertainment';
    }
    if (_contains(title, const <String>['book', 'course', 'tuition'])) {
      return 'education';
    }
    if (_contains(title, const <String>['bill', 'electricity', 'internet'])) {
      return 'utilities';
    }
    if (_contains(title, const <String>['pharmacy', 'doctor', 'health'])) {
      return 'health';
    }

    for (final String tag in tags) {
      final String normalized = tag.trim().toLowerCase();
      if (categoryCatalog.contains(normalized)) {
        return normalized;
      }
    }

    return 'misc';
  }

  Future<void> _createSimulatedTransaction({
    required String userId,
    required String accountId,
    required String title,
    required double amount,
    required TransactionType type,
    required String source,
    required String channel,
    List<String> tags = const <String>[],
  }) async {
    final DateTime now = DateTime.now().toUtc();
    final String category = suggestCategory(title: title, type: type, tags: tags);

    final FinanceTransaction tx = FinanceTransaction(
      id: _uuid.v4(),
      userId: userId,
      accountId: accountId,
      title: title,
      amount: amount,
      type: type,
      category: category,
      tags: tags,
      note: 'Simulated transaction',
      source: source,
      channel: channel,
      isCategoryOverridden: false,
      transactionAt: now,
      createdAt: now,
      updatedAt: now,
    );

    await _transactionService.createTransaction(tx);
  }

  bool _contains(String text, List<String> keywords) {
    final String normalized = text.toLowerCase();
    return keywords.any(normalized.contains);
  }
}
