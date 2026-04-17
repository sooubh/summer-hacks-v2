import 'package:student_fin_os/models/account.dart';
import 'package:student_fin_os/models/finance_enums.dart';
import 'package:student_fin_os/models/finance_transaction.dart';

class AccountAggregationSnapshot {
  const AccountAggregationSnapshot({
    required this.accounts,
    required this.unifiedTransactions,
    required this.totalBalance,
    required this.monthlySpendByKey,
    required this.spendingByCategory,
    required this.currentMonthSpend,
    required this.previousMonthSpend,
  });

  final List<Account> accounts;
  final List<FinanceTransaction> unifiedTransactions;
  final double totalBalance;
  final Map<String, double> monthlySpendByKey;
  final Map<String, double> spendingByCategory;
  final double currentMonthSpend;
  final double previousMonthSpend;

  double get monthlyTrendPercent {
    if (previousMonthSpend <= 0) {
      return currentMonthSpend > 0 ? 100 : 0;
    }
    return ((currentMonthSpend - previousMonthSpend) / previousMonthSpend) * 100;
  }

  bool get isSpendingIncreased => monthlyTrendPercent > 0;

  static AccountAggregationSnapshot empty() {
    return const AccountAggregationSnapshot(
      accounts: <Account>[],
      unifiedTransactions: <FinanceTransaction>[],
      totalBalance: 0,
      monthlySpendByKey: <String, double>{},
      spendingByCategory: <String, double>{},
      currentMonthSpend: 0,
      previousMonthSpend: 0,
    );
  }

  factory AccountAggregationSnapshot.fromData({
    required List<Account> accounts,
    required List<FinanceTransaction> transactions,
  }) {
    final DateTime now = DateTime.now().toUtc();

    double totalBalance = 0;
    for (final Account account in accounts) {
      totalBalance += account.balance;
    }

    final Map<String, double> monthlySpend = <String, double>{};
    final Map<String, double> categories = <String, double>{};
    double currentMonthSpend = 0;
    double previousMonthSpend = 0;

    for (final FinanceTransaction tx in transactions) {
      if (tx.type != TransactionType.expense) {
        continue;
      }

      final DateTime ts = tx.transactionAt;
      final String monthKey = _monthKey(ts);
      monthlySpend.update(monthKey, (double v) => v + tx.amount, ifAbsent: () => tx.amount);

      if (_isInLastDays(ts, now, 30)) {
        categories.update(tx.category, (double v) => v + tx.amount, ifAbsent: () => tx.amount);
      }

      if (ts.year == now.year && ts.month == now.month) {
        currentMonthSpend += tx.amount;
      }

      final DateTime prevMonth = DateTime.utc(now.year, now.month - 1, 1);
      if (ts.year == prevMonth.year && ts.month == prevMonth.month) {
        previousMonthSpend += tx.amount;
      }
    }

    return AccountAggregationSnapshot(
      accounts: accounts,
      unifiedTransactions: transactions,
      totalBalance: totalBalance,
      monthlySpendByKey: monthlySpend,
      spendingByCategory: categories,
      currentMonthSpend: currentMonthSpend,
      previousMonthSpend: previousMonthSpend,
    );
  }

  static String _monthKey(DateTime value) {
    return '${value.year}-${value.month.toString().padLeft(2, '0')}';
  }

  static bool _isInLastDays(DateTime value, DateTime now, int days) {
    return now.difference(value).inDays <= days;
  }
}
