import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_fin_os/models/account.dart';
import 'package:student_fin_os/models/account_aggregation_snapshot.dart';
import 'package:student_fin_os/models/dashboard_snapshot.dart';
import 'package:student_fin_os/models/finance_enums.dart';
import 'package:student_fin_os/models/finance_transaction.dart';
import 'package:student_fin_os/models/savings_goal.dart';
import 'package:student_fin_os/providers/auth_providers.dart';
import 'package:student_fin_os/providers/firebase_providers.dart';

class UnifiedPlatformSummary {
  const UnifiedPlatformSummary({
    required this.bankBalance,
    required this.upiBalance,
    required this.cashBalance,
    required this.totalAccounts,
    required this.totalTransactions,
  });

  final double bankBalance;
  final double upiBalance;
  final double cashBalance;
  final int totalAccounts;
  final int totalTransactions;

  static const UnifiedPlatformSummary empty = UnifiedPlatformSummary(
    bankBalance: 0,
    upiBalance: 0,
    cashBalance: 0,
    totalAccounts: 0,
    totalTransactions: 0,
  );
}

final accountsProvider = StreamProvider.autoDispose<List<Account>>((ref) {
  final String? userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return Stream<List<Account>>.value(const <Account>[]);
  }
  return ref.watch(accountServiceProvider).watchAccounts(userId);
});

final transactionsProvider = StreamProvider.autoDispose<List<FinanceTransaction>>((ref) {
  final String? userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return Stream<List<FinanceTransaction>>.value(const <FinanceTransaction>[]);
  }
  return ref.watch(transactionServiceProvider).watchTransactions(userId);
});

final savingsGoalsProvider = StreamProvider.autoDispose<List<SavingsGoal>>((ref) {
  final String? userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return Stream<List<SavingsGoal>>.value(const <SavingsGoal>[]);
  }
  return ref.watch(savingsServiceProvider).watchGoals(userId);
});

final dashboardSnapshotProvider = Provider<DashboardSnapshot>((ref) {
  final AccountAggregationSnapshot unified =
      ref.watch(aggregationSnapshotProvider).value ?? AccountAggregationSnapshot.empty();
  final List<SavingsGoal> goals =
      ref.watch(savingsGoalsProvider).value ?? const <SavingsGoal>[];

  final DateTime now = DateTime.now().toUtc();

  final List<FinanceTransaction> expenses = unified.unifiedTransactions
      .where((FinanceTransaction tx) => tx.type == TransactionType.expense)
      .toList();

  double weeklySpend = 0;
  double monthlySpend = 0;
  final Map<String, double> categories = <String, double>{};

  for (final FinanceTransaction tx in expenses) {
    final int days = now.difference(tx.transactionAt).inDays;
    if (days <= 7) {
      weeklySpend += tx.amount;
    }
    if (days <= 30) {
      monthlySpend += tx.amount;
      categories.update(tx.category, (double value) => value + tx.amount,
          ifAbsent: () => tx.amount);
    }
  }

  double monthlyGoalContribution = 0;
  for (final SavingsGoal goal in goals) {
    if (goal.status == GoalStatus.active) {
      monthlyGoalContribution +=
          ref.watch(savingsServiceProvider).recommendedMonthlyContribution(goal);
    }
  }

  final double safeToSpend = ref.watch(savingsServiceProvider).calculateSafeToSpend(
      totalBalance: unified.totalBalance,
        weeklyExpectedSpend: weeklySpend,
        monthlyGoalContribution: monthlyGoalContribution,
      );

  final int dayOfMonth = now.day.clamp(1, 31);
  final double burnRate = monthlySpend / dayOfMonth;

  return DashboardSnapshot(
    totalBalance: unified.totalBalance,
    weeklySpend: weeklySpend,
    monthlySpend: monthlySpend,
    burnRate: burnRate,
    safeToSpend: safeToSpend,
    categoryBreakdown: unified.spendingByCategory.isEmpty
        ? categories
        : unified.spendingByCategory,
    monthlySpendByKey: unified.monthlySpendByKey,
    currentMonthSpend: unified.currentMonthSpend,
    previousMonthSpend: unified.previousMonthSpend,
    unifiedTransactions: unified.unifiedTransactions,
  );
});

final aggregationSnapshotProvider =
    StreamProvider.autoDispose<AccountAggregationSnapshot>((ref) {
  final String? userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return Stream<AccountAggregationSnapshot>.value(AccountAggregationSnapshot.empty());
  }

  return ref.watch(aggregatorServiceProvider).watchUnifiedSnapshot(userId);
});

final unifiedPlatformSummaryProvider = Provider<UnifiedPlatformSummary>((ref) {
  final List<Account> accounts = ref.watch(accountsProvider).value ?? const <Account>[];
  final List<FinanceTransaction> transactions =
      ref.watch(transactionsProvider).value ?? const <FinanceTransaction>[];

  double bank = 0;
  double upi = 0;
  double cash = 0;

  for (final Account account in accounts) {
    switch (account.type) {
      case AccountType.bank:
        bank += account.balance;
      case AccountType.upi:
        upi += account.balance;
      case AccountType.cash:
        cash += account.balance;
    }
  }

  return UnifiedPlatformSummary(
    bankBalance: bank,
    upiBalance: upi,
    cashBalance: cash,
    totalAccounts: accounts.length,
    totalTransactions: transactions.length,
  );
});
