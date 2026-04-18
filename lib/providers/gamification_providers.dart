import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_fin_os/models/finance_transaction.dart';
import 'package:student_fin_os/models/gamification_models.dart';
import 'package:student_fin_os/providers/dashboard_providers.dart';

final gamificationProvider = Provider<FinRewardProfile>((ref) {
  final snapshot = ref.watch(dashboardSnapshotProvider);
  final List<FinanceTransaction> transactions =
      ref.watch(transactionsProvider).value ?? const <FinanceTransaction>[];

  final DateTime now = DateTime.now();
  final int currentYear = now.year;
  final int currentMonth = now.month;

  final List<FinanceTransaction> monthTransactions = transactions
      .where((FinanceTransaction tx) {
        final DateTime dt = tx.transactionAt.toLocal();
        return dt.year == currentYear && dt.month == currentMonth;
      })
      .toList(growable: false);

  final int totalTransactions = transactions.length;
  final int monthlyTransactions = monthTransactions.length;
  final int upiTransactions = transactions.where((FinanceTransaction tx) {
    return tx.channel.toLowerCase() == 'upi';
  }).length;
  final int manualCategoryFixes = transactions.where((FinanceTransaction tx) {
    return tx.isCategoryOverridden;
  }).length;
  final int savingsProgress = snapshot.totalSavings <= 0
      ? 0
      : snapshot.totalSavings.floor();
  final int activeSpendDays = _countUniqueSpendDays(monthTransactions);
  final int streakDays = _dailyStreak(transactions, now);

  final double monthIncome = monthTransactions
      .where((FinanceTransaction tx) => tx.isIncome)
      .fold<double>(0, (double sum, FinanceTransaction tx) => sum + tx.amount);
  final double monthExpense = monthTransactions
      .where((FinanceTransaction tx) => tx.isExpense)
      .fold<double>(0, (double sum, FinanceTransaction tx) => sum + tx.amount);
  final bool healthyCashflowMonth =
      monthIncome >= monthExpense && monthlyTransactions >= 10;

  final List<RewardActivity> activities = <RewardActivity>[
    RewardActivity(
      id: 'activity_tx_month',
      title: 'Monthly Money Tracking',
      description: 'Log at least 30 transactions this month.',
      icon: '🗓️',
      currentProgress: monthlyTransactions,
      targetProgress: 30,
      coinReward: 120,
      isCompleted: monthlyTransactions >= 30,
    ),
    RewardActivity(
      id: 'activity_streak',
      title: '7-Day Finance Streak',
      description: 'Stay active on finance updates for 7 straight days.',
      icon: '🔥',
      currentProgress: streakDays,
      targetProgress: 7,
      coinReward: 140,
      isCompleted: streakDays >= 7,
    ),
    RewardActivity(
      id: 'activity_upi',
      title: 'UPI Activity Tracker',
      description: 'Track 20 UPI payments clearly.',
      icon: '📲',
      currentProgress: upiTransactions,
      targetProgress: 20,
      coinReward: 90,
      isCompleted: upiTransactions >= 20,
    ),
    RewardActivity(
      id: 'activity_category_fix',
      title: 'Category Cleanup',
      description: 'Review and fix category tags at least 5 times.',
      icon: '🧩',
      currentProgress: manualCategoryFixes,
      targetProgress: 5,
      coinReward: 70,
      isCompleted: manualCategoryFixes >= 5,
    ),
    RewardActivity(
      id: 'activity_savings_buffer',
      title: 'Build 10k Safety Buffer',
      description: 'Grow your saved amount to 10,000.',
      icon: '🏦',
      currentProgress: savingsProgress,
      targetProgress: 10000,
      coinReward: 220,
      isCompleted: savingsProgress >= 10000,
    ),
    RewardActivity(
      id: 'activity_cashflow_health',
      title: 'Healthy Monthly Cashflow',
      description: 'Keep monthly income above expense with enough activity.',
      icon: '✅',
      currentProgress: healthyCashflowMonth ? 1 : 0,
      targetProgress: 1,
      coinReward: 100,
      isCompleted: healthyCashflowMonth,
    ),
  ];

  final List<RewardBadge> badges = <RewardBadge>[
    RewardBadge(
      id: 'first_save',
      name: 'First Saver',
      description: 'Save your first amount and start building momentum.',
      icon: '🌱',
      isUnlocked: snapshot.totalSavings > 0,
      coinReward: 60,
      currentProgress: snapshot.totalSavings > 0 ? 1 : 0,
      targetProgress: 1,
    ),
    RewardBadge(
      id: 'budget_master',
      name: 'Budget Guardian',
      description: 'Maintain a positive safe-to-spend balance.',
      icon: '🛡️',
      isUnlocked: snapshot.safeToSpend > 0,
      coinReward: 90,
      currentProgress: snapshot.safeToSpend > 0 ? 1 : 0,
      targetProgress: 1,
    ),
    RewardBadge(
      id: 'low_burn',
      name: 'Low Burn Pro',
      description: 'Keep daily burn rate under 500.',
      icon: '🔥',
      isUnlocked: snapshot.burnRate < 500 && snapshot.burnRate > 0,
      coinReward: 120,
      currentProgress: (snapshot.burnRate < 500 && snapshot.burnRate > 0) ? 1 : 0,
      targetProgress: 1,
    ),
    RewardBadge(
      id: 'investor_mindset',
      name: 'Investor Mind',
      description: 'Accumulate at least 10,000 in savings.',
      icon: '📈',
      isUnlocked: savingsProgress >= 10000,
      coinReward: 180,
      currentProgress: savingsProgress,
      targetProgress: 10000,
    ),
    RewardBadge(
      id: 'activity_champion',
      name: 'Activity Champion',
      description: 'Track 50 transactions across all accounts.',
      icon: '🏃',
      isUnlocked: totalTransactions >= 50,
      coinReward: 130,
      currentProgress: totalTransactions,
      targetProgress: 50,
    ),
    RewardBadge(
      id: 'streak_guardian',
      name: 'Streak Guardian',
      description: 'Hold a 7-day transaction streak.',
      icon: '🏅',
      isUnlocked: streakDays >= 7,
      coinReward: 150,
      currentProgress: streakDays,
      targetProgress: 7,
    ),
    RewardBadge(
      id: 'upi_ninja',
      name: 'UPI Ninja',
      description: 'Track 25 UPI transactions.',
      icon: '⚡',
      isUnlocked: upiTransactions >= 25,
      coinReward: 110,
      currentProgress: upiTransactions,
      targetProgress: 25,
    ),
    RewardBadge(
      id: 'cashflow_keeper',
      name: 'Cashflow Keeper',
      description: 'Close this month with healthy cashflow.',
      icon: '💡',
      isUnlocked: healthyCashflowMonth,
      coinReward: 100,
      currentProgress: healthyCashflowMonth ? 1 : 0,
      targetProgress: 1,
    ),
  ];

  final int completedActivities = activities
      .where((RewardActivity activity) => activity.isCompleted)
      .length;
  final int unlockedBadgesCount =
      badges.where((RewardBadge badge) => badge.isUnlocked).length;

  int coins = 0;
  coins += (snapshot.totalSavings / 20).floor();
  coins += totalTransactions * 2;
  coins += activeSpendDays * 4;
  coins += completedActivities * 40;
  coins += unlockedBadgesCount * 65;

  if (snapshot.safeToSpend > 0) {
    coins += 35;
  }
  if (snapshot.burnRate < 500 && snapshot.burnRate > 0) {
    coins += 90;
  }
  if (streakDays >= 7) {
    coins += 60;
  }
  if (monthlyTransactions >= 20) {
    coins += 50;
  }

  const List<_RankBand> ranks = <_RankBand>[
    _RankBand(name: 'Novice Saver', minCoins: 0),
    _RankBand(name: 'Bronze Saver', minCoins: 300),
    _RankBand(name: 'Silver Investor', minCoins: 900),
    _RankBand(name: 'Gold Wealth Builder', minCoins: 2200),
    _RankBand(name: 'Platinum Planner', minCoins: 5000),
    _RankBand(name: 'Finance Legend', minCoins: 9000),
  ];

  String currentRank = ranks.first.name;
  String nextRank = ranks[1].name;
  double progress = 0;
  int coinsToNextRank = ranks[1].minCoins - coins;

  for (int i = 0; i < ranks.length - 1; i++) {
    final _RankBand current = ranks[i];
    final _RankBand next = ranks[i + 1];
    if (coins < next.minCoins) {
      currentRank = current.name;
      nextRank = next.name;
      final int span = next.minCoins - current.minCoins;
      progress = span <= 0 ? 1 : (coins - current.minCoins) / span;
      coinsToNextRank = next.minCoins - coins;
      break;
    }

    if (i == ranks.length - 2) {
      currentRank = ranks.last.name;
      nextRank = 'Max Level';
      progress = 1;
      coinsToNextRank = 0;
    }
  }

  final String nextBestAction = _nextBestAction(activities);

  return FinRewardProfile(
    totalFinCoins: coins,
    currentRank: currentRank,
    nextRank: nextRank,
    progressToNextRank: progress.clamp(0.0, 1.0),
    coinsToNextRank: coinsToNextRank < 0 ? 0 : coinsToNextRank,
    unlockedBadgesCount: unlockedBadgesCount,
    nextBestAction: nextBestAction,
    activities: activities,
    badges: badges,
  );
});

class _RankBand {
  const _RankBand({
    required this.name,
    required this.minCoins,
  });

  final String name;
  final int minCoins;
}

int _countUniqueSpendDays(List<FinanceTransaction> transactions) {
  final Set<DateTime> days = <DateTime>{};
  for (final FinanceTransaction tx in transactions) {
    if (!tx.isExpense) {
      continue;
    }
    final DateTime local = tx.transactionAt.toLocal();
    days.add(DateTime(local.year, local.month, local.day));
  }
  return days.length;
}

int _dailyStreak(List<FinanceTransaction> transactions, DateTime now) {
  if (transactions.isEmpty) {
    return 0;
  }

  final Set<DateTime> activeDays = <DateTime>{};
  for (final FinanceTransaction tx in transactions) {
    final DateTime local = tx.transactionAt.toLocal();
    activeDays.add(DateTime(local.year, local.month, local.day));
  }

  int streak = 0;
  DateTime cursor = DateTime(now.year, now.month, now.day);
  while (activeDays.contains(cursor)) {
    streak += 1;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}

String _nextBestAction(List<RewardActivity> activities) {
  final List<RewardActivity> remaining = activities
      .where((RewardActivity activity) => !activity.isCompleted)
      .toList(growable: false);

  if (remaining.isEmpty) {
    return 'All activities completed. Keep consistency to hold your rank.';
  }

  final List<RewardActivity> ranked = List<RewardActivity>.from(remaining)
    ..sort((RewardActivity a, RewardActivity b) {
      final int byProgress = b.progress.compareTo(a.progress);
      if (byProgress != 0) {
        return byProgress;
      }
      return b.coinReward.compareTo(a.coinReward);
    });

  final RewardActivity next = ranked.first;
  return 'Next best: ${next.title} (+${next.coinReward} coins). Remaining: ${next.remainingProgress}.';
}