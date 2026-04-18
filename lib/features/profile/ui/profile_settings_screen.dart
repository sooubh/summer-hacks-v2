import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:student_fin_os/core/utils/currency_formatter.dart';
import 'package:student_fin_os/features/rewards/ui/rewards_screen.dart';
import 'package:student_fin_os/models/finance_transaction.dart';
import 'package:student_fin_os/models/gamification_models.dart';
import 'package:student_fin_os/providers/auth_providers.dart';
import 'package:student_fin_os/providers/dashboard_providers.dart';
import 'package:student_fin_os/providers/firebase_providers.dart';
import 'package:student_fin_os/providers/gamification_providers.dart';

class ProfileSettingsScreen extends ConsumerWidget {
  const ProfileSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(firebaseAuthProvider).currentUser;
    final profile = ref.watch(gamificationProvider);
    final snapshot = ref.watch(dashboardSnapshotProvider);
    final List<FinanceTransaction> txList =
        ref.watch(transactionsProvider).value ?? const <FinanceTransaction>[];

    final int streak = _dailyStreak(txList);
    final _SpendingHabits habits = _buildSpendingHabits(snapshot, txList);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _profileHeader(context, user),
          const SizedBox(height: 12),
          _statsRow(context, profile, streak),
          const SizedBox(height: 12),
          _rewardsSection(context, profile),
          const SizedBox(height: 12),
          _spendingHabitsSection(context, habits),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign out'),
              subtitle: const Text('Log out from this device'),
              onTap: () {
                ref.read(authControllerProvider.notifier).signOut();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileHeader(BuildContext context, dynamic user) {
    final String displayName =
        (user?.displayName as String?)?.trim().isNotEmpty == true
            ? user.displayName as String
            : 'Student';
    final String email =
        (user?.email as String?)?.trim().isNotEmpty == true
            ? user.email as String
            : 'No email linked';
    final String? photoUrl = user?.photoURL as String?;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              radius: 30,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                  ? NetworkImage(photoUrl)
                  : null,
              child: (photoUrl == null || photoUrl.isEmpty)
                  ? Text(
                      displayName.isNotEmpty
                          ? displayName.substring(0, 1).toUpperCase()
                          : 'S',
                      style: Theme.of(context).textTheme.titleLarge,
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    displayName,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(email, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 6),
                  Text(
                    'Personalized rewards, streaks, and spending habits',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statsRow(
    BuildContext context,
    FinRewardProfile profile,
    int streak,
  ) {
    Widget tile({
      required IconData icon,
      required String label,
      required String value,
    }) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            children: <Widget>[
              Icon(icon, size: 18),
              const SizedBox(height: 6),
              Text(
                value,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(label, style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ),
      );
    }

    return Row(
      children: <Widget>[
        tile(
          icon: Icons.stars_rounded,
          label: 'FinCoins',
          value: '${profile.totalFinCoins}',
        ),
        const SizedBox(width: 8),
        tile(
          icon: Icons.local_fire_department_outlined,
          label: 'Daily Streak',
          value: '$streak day${streak == 1 ? '' : 's'}',
        ),
        const SizedBox(width: 8),
        tile(
          icon: Icons.military_tech_outlined,
          label: 'Rank',
          value: profile.currentRank,
        ),
      ],
    );
  }

  Widget _rewardsSection(BuildContext context, FinRewardProfile profile) {
    final List<RewardBadge> unlocked = profile.badges
        .where((RewardBadge badge) => badge.isUnlocked)
        .toList(growable: false);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.emoji_events_outlined),
                const SizedBox(width: 8),
                Text(
                  'Rewards',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const RewardsScreen(),
                      ),
                    );
                  },
                  child: const Text('View all'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Unlocked ${unlocked.length}/${profile.badges.length} badges',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            if (unlocked.isEmpty)
              const Text('No rewards unlocked yet. Keep tracking consistently.')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: unlocked.map((RewardBadge badge) {
                  return Chip(
                    avatar: CircleAvatar(
                      child: Text(
                        badge.icon,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    label: Text(badge.name),
                  );
                }).toList(growable: false),
              ),
          ],
        ),
      ),
    );
  }

  Widget _spendingHabitsSection(BuildContext context, _SpendingHabits habits) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.insights_outlined),
                const SizedBox(width: 8),
                Text(
                  'Spending Habits',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(habits.summary),
            const SizedBox(height: 12),
            _habitRow(
              context,
              label: 'Top category',
              value: habits.topCategory,
            ),
            _habitRow(
              context,
              label: 'Average daily spend',
              value: CurrencyFormatter.inr(habits.avgDailySpend),
            ),
            _habitRow(
              context,
              label: 'Average transaction',
              value: CurrencyFormatter.inr(habits.avgTransactionAmount),
            ),
            _habitRow(
              context,
              label: 'Savings ratio',
              value: '${habits.savingsRatioPercent.toStringAsFixed(1)}%',
            ),
            _habitRow(
              context,
              label: 'Active spend days (this month)',
              value: '${habits.activeSpendDays}',
            ),
            const SizedBox(height: 8),
            Text(
              habits.actionTip,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _habitRow(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label)),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  int _dailyStreak(List<FinanceTransaction> transactions) {
    if (transactions.isEmpty) {
      return 0;
    }

    final Set<DateTime> activityDays = <DateTime>{};
    for (final FinanceTransaction tx in transactions) {
      final DateTime local = tx.transactionAt.toLocal();
      activityDays.add(DateTime(local.year, local.month, local.day));
    }

    DateTime cursor = DateTime.now();
    cursor = DateTime(cursor.year, cursor.month, cursor.day);

    if (!activityDays.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }

    int streak = 0;
    while (activityDays.contains(cursor)) {
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return streak;
  }

  _SpendingHabits _buildSpendingHabits(
    dynamic snapshot,
    List<FinanceTransaction> transactions,
  ) {
    final DateTime now = DateTime.now();
    final List<FinanceTransaction> monthTx = transactions.where((FinanceTransaction tx) {
      final DateTime local = tx.transactionAt.toLocal();
      return local.year == now.year && local.month == now.month && tx.isExpense;
    }).toList(growable: false);

    final double totalMonthExpense = monthTx.fold<double>(
      0,
      (double sum, FinanceTransaction tx) => sum + tx.amount,
    );
    final double avgTx = monthTx.isEmpty ? 0 : totalMonthExpense / monthTx.length;
    final double avgDaily = totalMonthExpense / now.day.clamp(1, 31);

    final Set<String> activeDates = monthTx.map((FinanceTransaction tx) {
      final DateTime local = tx.transactionAt.toLocal();
      return DateFormat('yyyy-MM-dd').format(local);
    }).toSet();

    final double savingsRatio = (snapshot.totalSavings + totalMonthExpense) <= 0
        ? 0
        : (snapshot.totalSavings / (snapshot.totalSavings + totalMonthExpense)) * 100;

    final String habitBand;
    if (snapshot.safeToSpend < 0) {
      habitBand = 'High pressure spending pattern';
    } else if (snapshot.burnRate > 700) {
      habitBand = 'Aggressive spending pattern';
    } else if (snapshot.burnRate > 350) {
      habitBand = 'Balanced spending pattern';
    } else {
      habitBand = 'Disciplined spending pattern';
    }

    final String summary =
        '$habitBand. You spend around ${CurrencyFormatter.inr(avgDaily)} per day this month, '
        'with ${snapshot.topCategory} as your largest category.';

    final String actionTip = snapshot.safeToSpend <= 0
        ? 'Action: hold optional purchases for 3-5 days to recover your safe-to-spend zone.'
        : 'Action: cap your daily optional spending under ${CurrencyFormatter.inr(snapshot.safeToSpend / 7)} for better consistency.';

    return _SpendingHabits(
      topCategory: snapshot.topCategory,
      avgDailySpend: avgDaily,
      avgTransactionAmount: avgTx,
      savingsRatioPercent: savingsRatio,
      activeSpendDays: activeDates.length,
      summary: summary,
      actionTip: actionTip,
    );
  }
}

class _SpendingHabits {
  const _SpendingHabits({
    required this.topCategory,
    required this.avgDailySpend,
    required this.avgTransactionAmount,
    required this.savingsRatioPercent,
    required this.activeSpendDays,
    required this.summary,
    required this.actionTip,
  });

  final String topCategory;
  final double avgDailySpend;
  final double avgTransactionAmount;
  final double savingsRatioPercent;
  final int activeSpendDays;
  final String summary;
  final String actionTip;
}
