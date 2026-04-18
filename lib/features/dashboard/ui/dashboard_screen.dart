import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_fin_os/core/utils/currency_formatter.dart';
import 'package:student_fin_os/core/widgets/empty_state.dart';
import 'package:student_fin_os/core/widgets/metric_card.dart';
import 'package:student_fin_os/core/widgets/section_header.dart';
import 'package:student_fin_os/l10n/app_localizations.dart';
import 'package:student_fin_os/models/dashboard_snapshot.dart';
import 'package:student_fin_os/models/finance_transaction.dart';
import 'package:student_fin_os/models/finance_enums.dart';
import 'package:student_fin_os/models/savings_goal.dart';
import 'package:student_fin_os/providers/dashboard_providers.dart';
import 'package:student_fin_os/features/dashboard/ui/transaction_details_sheet.dart';
import 'package:student_fin_os/providers/auth_providers.dart';
import 'package:student_fin_os/providers/firebase_providers.dart';
import 'package:student_fin_os/core/utils/brand_styles.dart';
import 'package:student_fin_os/core/utils/dummy_data.dart';
import 'package:student_fin_os/features/dashboard/ui/spending_modules_screen.dart';
import 'package:student_fin_os/providers/gamification_providers.dart';
import 'package:student_fin_os/features/rewards/ui/rewards_screen.dart';
import 'package:student_fin_os/features/assistant/ui/chat_assistant_screen.dart';
import 'package:uuid/uuid.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isSeeding = false;
  bool _isBalanceVisible = true;

  void _openHomeDetailsSheet(
    BuildContext context, {
    required DashboardSnapshot snapshot,
    required List<FinanceTransaction> transactions,
    required List<SavingsGoal> savingsGoals,
    String topic = 'all',
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) {
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: _HomeDetailsSheet(
            snapshot: snapshot,
            transactions: transactions,
            savingsGoals: savingsGoals,
            topic: topic,
          ),
        );
      },
    );
  }

  Future<void> _injectDummyTransactions() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    final txService = ref.read(transactionServiceProvider);
    final accountService = ref.read(accountServiceProvider);

    final accounts = await accountService.watchAccounts(userId).first;
    if (accounts.isEmpty) return;

    setState(() => _isSeeding = true);

    int seededCount = 0;
    int skippedCount = 0;

    try {
      final now = DateTime.now();
      final uid = const Uuid();
      final List<Map<String, dynamic>> dummies = generateDummyTransactions();

      final Map<String, double> projectedBalanceByAccount = <String, double>{
        for (final account in accounts) account.id: account.balance,
      };

      for (int i = 0; i < dummies.length; i++) {
        final d = dummies[i];
        final bool isExpense = d['isIncome'] != true;
        final double amount = ((d['amount'] as num?)?.toDouble() ?? 0).abs();
        if (amount <= 0) {
          skippedCount += 1;
          continue;
        }

        final String source = ((d['src'] as String?) ?? 'manual').trim();
        final String channel = (((d['channel'] as String?) ?? '')
                    .trim()
                    .toLowerCase()
                    .isEmpty)
            ? _inferChannelFromSource(source)
            : (d['channel'] as String).trim().toLowerCase();

        final String accountId = _pickAccountIdForSeed(
          accounts,
          projectedBalanceByAccount,
          channel: channel,
          amount: amount,
          isExpense: isExpense,
        );
        if (accountId.isEmpty) {
          skippedCount += 1;
          continue;
        }

        if (isExpense) {
          final double current = projectedBalanceByAccount[accountId] ?? 0;
          if (current < amount) {
            skippedCount += 1;
            continue;
          }
          projectedBalanceByAccount[accountId] = current - amount;
        } else {
          final double current = projectedBalanceByAccount[accountId] ?? 0;
          projectedBalanceByAccount[accountId] = current + amount;
        }

        final tx = FinanceTransaction(
          id: uid.v4(),
          userId: userId,
          accountId: accountId,
          title: ((d['title'] as String?) ?? 'Seed Transaction').trim(),
          amount: amount,
          type: isExpense ? TransactionType.expense : TransactionType.income,
          category: ((d['cat'] as String?) ?? 'misc').trim(),
          transactionAt: now.subtract(Duration(days: i)),
          createdAt: now,
          updatedAt: now,
          source: source.isEmpty ? 'manual' : source,
          channel: channel,
        );

        await txService.createTransaction(tx);
        seededCount += 1;
      }
    } finally {
      if (mounted) {
        setState(() => _isSeeding = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              skippedCount > 0
                  ? 'Seeded $seededCount transactions, skipped $skippedCount to avoid negative balance.'
                  : 'Seeded $seededCount transactions.',
            ),
          ),
        );
      }
    }
  }

  String _pickAccountIdForSeed(
    List<dynamic> accounts,
    Map<String, double> balanceByAccount, {
    required String channel,
    required double amount,
    required bool isExpense,
  }) {
    String? preferredId;
    final String normalizedChannel = channel.toLowerCase();

    for (final account in accounts) {
      final String accountType = account.type.toString().toLowerCase();
      if (normalizedChannel == 'cash' && accountType.contains('cash')) {
        preferredId = account.id as String;
        break;
      }
      if (normalizedChannel == 'upi' && accountType.contains('upi')) {
        preferredId = account.id as String;
        break;
      }
      if ((normalizedChannel == 'card' || normalizedChannel == 'bank_transfer') &&
          accountType.contains('bank')) {
        preferredId = account.id as String;
        break;
      }
    }

    final List<String> candidateIds = accounts
        .map((dynamic account) => account.id as String)
        .toList(growable: true);
    if (preferredId != null) {
      candidateIds.remove(preferredId);
      candidateIds.insert(0, preferredId);
    }

    if (!isExpense) {
      return candidateIds.isNotEmpty ? candidateIds.first : '';
    }

    for (final String id in candidateIds) {
      if ((balanceByAccount[id] ?? 0) >= amount) {
        return id;
      }
    }

    return '';
  }

  String _inferChannelFromSource(String source) {
    final String normalized = source.toLowerCase();
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
    return 'upi';
  }



  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final snapshot = ref.watch(dashboardSnapshotProvider);
    final List<FinanceTransaction> txList = snapshot.unifiedTransactions;
    final List<SavingsGoal> savingsGoals =
        ref.watch(savingsGoalsProvider).value ?? const <SavingsGoal>[];

    return SafeArea(
      child: CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Welcome back,', style: Theme.of(context).textTheme.bodyLarge),
                          Text('Ready to save?', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Consumer(
                        builder: (context, ref, child) {
                          final profile = ref.watch(gamificationProvider);
                          return InkWell(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RewardsScreen())),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha:0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.amber.withValues(alpha:0.5)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.stars, color: Colors.amber, size: 20),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${profile.totalFinCoins}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.amber),
                                ],
                              ),
                            ),
                          );
                        }
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _openHomeDetailsSheet(
                          context,
                          snapshot: snapshot,
                          transactions: txList,
                          savingsGoals: savingsGoals,
                          topic: 'all',
                        );
                      },
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text('View Full Details'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      _openHomeDetailsSheet(
                        context,
                        snapshot: snapshot,
                        transactions: txList,
                        savingsGoals: savingsGoals,
                        topic: 'overview',
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(l10n.totalBalance, style: Theme.of(context).textTheme.bodyMedium),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 260),
                                transitionBuilder: (Widget child, Animation<double> animation) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0, 0.08),
                                        end: Offset.zero,
                                      ).animate(animation),
                                      child: child,
                                    ),
                                  );
                                },
                                child: Text(
                                  _isBalanceVisible
                                      ? CurrencyFormatter.inr(snapshot.totalBalance)
                                      : '••••••',
                                  key: ValueKey<String>(
                                    '${_isBalanceVisible ? 'show' : 'hide'}-${snapshot.totalBalance.toStringAsFixed(2)}',
                                  ),
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: Icon(_isBalanceVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                                onPressed: () {
                                  setState(() {
                                    _isBalanceVisible = !_isBalanceVisible;
                                  });
                                },
                              )
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              _deltaItem(
                                context,
                                icon: Icons.arrow_upward,
                                title: l10n.income,
                                value: CurrencyFormatter.inr(
                                  txList
                                      .where((FinanceTransaction tx) => tx.isIncome)
                                      .fold<double>(
                                        0,
                                        (double s, FinanceTransaction tx) => s + tx.amount,
                                      ),
                                ),
                                positive: true,
                              ),
                              _deltaItem(
                                context,
                                icon: Icons.arrow_downward,
                                title: l10n.spent,
                                value: CurrencyFormatter.inr(snapshot.monthlySpend),
                                positive: false,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Money Out By Method',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 8),
                        _buildOutgoingMethodCircles(context, txList),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: MediaQuery.of(context).size.width > 700 ? 4 : 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.38,
                    children: <Widget>[
                      _tappableMetricCard(
                        context,
                        snapshot: snapshot,
                        transactions: txList,
                        savingsGoals: savingsGoals,
                        topic: 'all',
                        child: MetricCard(
                          label: 'Total Saved',
                          value: CurrencyFormatter.inr(snapshot.totalSavings),
                          gradient: const <Color>[Color(0xFF8ABF9E), Color(0xFF68A57F)],
                          suggestionIcon: Icons.trending_up,
                          suggestionText: 'Good progress',
                          suggestionColor: Colors.green,
                        ),
                      ),
                      _tappableMetricCard(
                        context,
                        snapshot: snapshot,
                        transactions: txList,
                        savingsGoals: savingsGoals,
                        topic: 'safe_to_spend',
                        child: MetricCard(
                          label: l10n.safeToSpend,
                          value: CurrencyFormatter.inr(snapshot.safeToSpend),
                          gradient: const <Color>[Color(0xFF8CB6D9), Color(0xFF6A9BC8)],
                          suggestionIcon: Icons.check_circle_outline,
                          suggestionText: 'Stress-free limit',
                          suggestionColor: Colors.blue,
                        ),
                      ),
                      _tappableMetricCard(
                        context,
                        snapshot: snapshot,
                        transactions: txList,
                        savingsGoals: savingsGoals,
                        topic: 'weekly_spend',
                        child: MetricCard(
                          label: l10n.weeklySpend,
                          value: CurrencyFormatter.inr(snapshot.weeklySpend),
                          gradient: const <Color>[Color(0xFFC6B4DF), Color(0xFFAA93CE)],
                          suggestionIcon: Icons.insights,
                          suggestionText: 'Track it closely',
                          suggestionColor: Colors.purple,
                        ),
                      ),
                      _tappableMetricCard(
                        context,
                        snapshot: snapshot,
                        transactions: txList,
                        savingsGoals: savingsGoals,
                        topic: 'burn_rate',
                        child: MetricCard(
                          label: l10n.burnRatePerDay,
                          value: CurrencyFormatter.inr(snapshot.burnRate),
                          gradient: const <Color>[Color(0xFFE8C59A), Color(0xFFD9AD74)],
                          suggestionIcon: Icons.warning_amber_rounded,
                          suggestionText: 'Keep it low',
                          suggestionColor: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const SectionHeader(
                    title: 'AI Quick Insights',
                    subtitle: 'Quick actions.',
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 96,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: <Widget>[
                        _AiStrategyCard(
                          icon: Icons.pie_chart_outline,
                          title: '50/30/20',
                          description: 'Set clear spend caps.',
                          color: Colors.blueAccent,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ChatAssistantScreen(
                                  initialMessage: 'Can we discuss setting up a 50/30/20 budget based on my recent spending?',
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        _AiStrategyCard(
                          icon: Icons.savings_outlined,
                          title: 'Auto-save 10%',
                          description: 'Grow goals automatically.',
                          color: Colors.green,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ChatAssistantScreen(
                                  initialMessage: 'How can I automate 10% of my income into an emergency fund? What are the best options?',
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        _AiStrategyCard(
                          icon: Icons.trending_up,
                          title: 'Index SIP',
                          description: 'Invest small, stay consistent.',
                          color: Colors.deepPurpleAccent,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ChatAssistantScreen(
                                  initialMessage: 'I want to start investing in Index Funds through SIPs to beat inflation. Can you guide me based on my balance?',
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const LearningModulesScreen(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.secondary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.school,
                            size: 32,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Smart Spending Hub',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.onPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Save money on Amazon, Zomato & more',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.9),
                                      ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Theme.of(context).colorScheme.secondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Lowers burn rate & improves AI predictions',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SectionHeader(
                    title: l10n.topSpendings,
                    subtitle: l10n.topSpendingsSubtitle,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: snapshot.categoryBreakdown.isEmpty
                        ? 120
                        : (snapshot.categoryBreakdown.length * 72.0).clamp(
                            144.0,
                            360.0,
                          ),
                    child: _topSpendingsRow(
                      context,
                      snapshot.categoryBreakdown,
                      transactions: txList,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SectionHeader(
                    title: l10n.monthlySpendingTrend,
                    subtitle: l10n.monthlySpendingTrendSubtitle,
                  ),
                  const SizedBox(height: 10),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            snapshot.previousMonthSpend <= 0
                                ? l10n.noPreviousMonthBaseline
                                : snapshot.isMonthlySpendUp
                                    ? l10n.spendingIncreasedBy(
                                        snapshot.monthlyTrendPercent.abs().toStringAsFixed(1),
                                      )
                                    : l10n.spendingDecreasedBy(
                                        snapshot.monthlyTrendPercent.abs().toStringAsFixed(1),
                                      ),
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: snapshot.isMonthlySpendUp
                                      ? Colors.orange.shade700
                                      : Colors.green.shade700,
                                ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 220,
                            child: snapshot.monthlySpendEntries.isEmpty
                                ? EmptyState(
                                  title: l10n.notEnoughMonthlyData,
                                  message: l10n.notEnoughMonthlyDataBody,
                                    icon: Icons.bar_chart,
                                  )
                                : LineChart(
                                  duration: const Duration(milliseconds: 420),
                                  curve: Curves.easeOutCubic,
                                    LineChartData(
                                      minX: 0,
                                      maxX:
                                          (snapshot.monthlySpendEntries.length - 1).toDouble(),
                                      minY: 0,
                                      maxY: _monthlyMaxY(snapshot.monthlySpendEntries),
                                      borderData: FlBorderData(show: false),
                                      gridData: FlGridData(
                                        show: true,
                                        drawVerticalLine: false,
                                        horizontalInterval:
                                            _monthlyMaxY(snapshot.monthlySpendEntries) / 4,
                                        getDrawingHorizontalLine: (double value) {
                                          return FlLine(
                                            color: Theme.of(context)
                                                .dividerColor
                                                .withValues(alpha: 0.7),
                                            strokeWidth: 1,
                                          );
                                        },
                                      ),
                                      titlesData: FlTitlesData(
                                        rightTitles: const AxisTitles(
                                          sideTitles: SideTitles(showTitles: false),
                                        ),
                                        topTitles: const AxisTitles(
                                          sideTitles: SideTitles(showTitles: false),
                                        ),
                                        leftTitles: const AxisTitles(
                                          sideTitles: SideTitles(showTitles: false),
                                        ),
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            getTitlesWidget: (double value, TitleMeta meta) {
                                              final int idx = value.toInt();
                                              if (idx < 0 ||
                                                  idx >= snapshot.monthlySpendEntries.length) {
                                                return const SizedBox.shrink();
                                              }
                                              return Padding(
                                                padding: const EdgeInsets.only(top: 6),
                                                child: Text(
                                                  _shortMonth(
                                                    snapshot.monthlySpendEntries[idx].key,
                                                  ),
                                                  style: Theme.of(context).textTheme.bodySmall,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      lineBarsData: <LineChartBarData>[
                                        LineChartBarData(
                                          spots: _buildMonthlyLineSpots(
                                            snapshot.monthlySpendEntries,
                                          ),
                                          isCurved: true,
                                          curveSmoothness: 0.25,
                                          color: const Color(0xFF4AA8FF),
                                          barWidth: 3,
                                          dotData: FlDotData(
                                            show: true,
                                            getDotPainter: (
                                              FlSpot spot,
                                              double percent,
                                              LineChartBarData bar,
                                              int index,
                                            ) {
                                              return FlDotCirclePainter(
                                                radius: 3.2,
                                                color: const Color(0xFF4AA8FF),
                                                strokeColor:
                                                    Theme.of(context).colorScheme.surface,
                                                strokeWidth: 1.2,
                                              );
                                            },
                                          ),
                                          belowBarData: BarAreaData(
                                            show: true,
                                            color: const Color(0xFF4AA8FF).withValues(alpha: 0.15),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SectionHeader(
                    title: l10n.categorySplit30d,
                    subtitle: l10n.categorySplitSubtitle,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 220,
                    child: snapshot.categoryBreakdown.isEmpty
                        ? EmptyState(
                          title: l10n.noCategoryDataYet,
                          message: l10n.noCategoryDataYetBody,
                            icon: Icons.pie_chart,
                          )
                        : Builder(
                            builder: (BuildContext context) {
                              final List<MapEntry<String, double>> categories =
                                  _sortedCategoryEntries(snapshot.categoryBreakdown);
                              return BarChart(
                                duration: const Duration(milliseconds: 420),
                                curve: Curves.easeOutCubic,
                                BarChartData(
                                  barGroups: _buildCategoryBars(categories),
                                  maxY: _categoryMaxY(categories),
                                  borderData: FlBorderData(show: false),
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: false,
                                    horizontalInterval:
                                        _categoryMaxY(categories) / 4,
                                    getDrawingHorizontalLine: (double value) {
                                      return FlLine(
                                        color: Theme.of(context)
                                            .dividerColor
                                            .withValues(alpha: 0.6),
                                        strokeWidth: 1,
                                      );
                                    },
                                  ),
                                  titlesData: FlTitlesData(
                                    rightTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    topTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    leftTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (double value, TitleMeta meta) {
                                          final int idx = value.toInt();
                                          if (idx < 0 || idx >= categories.length) {
                                            return const SizedBox.shrink();
                                          }
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 6),
                                            child: Text(
                                              _shortCategory(categories[idx].key),
                                              style: Theme.of(context).textTheme.bodySmall,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: _isSeeding ? null : _injectDummyTransactions,
                        icon: _isSeeding ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.add_box_outlined, color: Colors.blueGrey),
                        tooltip: 'Add Dummy Transactions',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (txList.isEmpty)
                    EmptyState(
                      title: l10n.noTransactionsFound,
                      message: l10n.noTransactionsFoundBody,
                      icon: Icons.receipt_long,
                    )
                  else
                    ...txList.take(6).toList().asMap().entries.map((entry) {
                      final FinanceTransaction tx = entry.value;
                      final int trueIndex = entry.key;
                      
                      final brandColor = BrandStyles.getColor(tx.title);
                      final brandIcon = BrandStyles.getIcon(tx.title, tx.category);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (ctx) => TransactionDetailsSheet(
                                transactions: txList.take(6).toList(),
                                initialIndex: trueIndex,
                              )
                            );
                          },
                          leading: CircleAvatar(
                            backgroundColor: brandColor.withValues(alpha: 0.15),
                            child: Icon(brandIcon, color: brandColor, size: 20),
                          ),
                          title: Text(tx.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            '${tx.category.toUpperCase()} • ${tx.source.toUpperCase()}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${tx.isExpense ? '-' : '+'}${CurrencyFormatter.inr(tx.amount)}',
                                style: TextStyle(
                                  color: tx.isExpense
                                      ? Theme.of(context).colorScheme.error
                                      : Colors.green.shade700,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Icon(
                                tx.isExpense ? Icons.south_west : Icons.north_east,
                                size: 12,
                                color: tx.isExpense
                                    ? Theme.of(context).colorScheme.error
                                    : Colors.green.shade700,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tappableMetricCard(
    BuildContext context, {
    required DashboardSnapshot snapshot,
    required List<FinanceTransaction> transactions,
    required List<SavingsGoal> savingsGoals,
    required String topic,
    required Widget child,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        _openHomeDetailsSheet(
          context,
          snapshot: snapshot,
          transactions: transactions,
          savingsGoals: savingsGoals,
          topic: topic,
        );
      },
      child: child,
    );
  }

  List<FlSpot> _buildMonthlyLineSpots(List<MapEntry<String, double>> entries) {
    return List<FlSpot>.generate(entries.length, (int index) {
      return FlSpot(index.toDouble(), entries[index].value);
    });
  }

  double _monthlyMaxY(List<MapEntry<String, double>> entries) {
    if (entries.isEmpty) {
      return 1000;
    }
    double max = 0;
    for (final MapEntry<String, double> entry in entries) {
      if (entry.value > max) {
        max = entry.value;
      }
    }
    return max * 1.2;
  }

  String _shortMonth(String monthKey) {
    final List<String> parts = monthKey.split('-');
    if (parts.length != 2) {
      return monthKey;
    }
    final int? month = int.tryParse(parts[1]);
    if (month == null || month < 1 || month > 12) {
      return monthKey;
    }
    const List<String> monthNames = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return monthNames[month - 1];
  }

  List<MapEntry<String, double>> _sortedCategoryEntries(
    Map<String, double> input,
  ) {
    final List<MapEntry<String, double>> entries = input.entries.toList()
      ..sort((MapEntry<String, double> a, MapEntry<String, double> b) {
        return b.value.compareTo(a.value);
      });
    return entries.take(6).toList(growable: false);
  }

  List<BarChartGroupData> _buildCategoryBars(
    List<MapEntry<String, double>> entries,
  ) {
    final List<Color> colors = <Color>[
      const Color(0xFF2AE4C9),
      const Color(0xFFFF7D66),
      const Color(0xFF4AA8FF),
      const Color(0xFFE2B93B),
      const Color(0xFF76E06E),
      const Color(0xFFF05E89),
    ];

    return List<BarChartGroupData>.generate(entries.length, (int index) {
      final MapEntry<String, double> entry = entries[index];
      return BarChartGroupData(
        x: index,
        barRods: <BarChartRodData>[
          BarChartRodData(
            toY: entry.value,
            width: 20,
            borderRadius: BorderRadius.circular(4),
            color: colors[index % colors.length],
          ),
        ],
      );
    });
  }

  double _categoryMaxY(List<MapEntry<String, double>> entries) {
    if (entries.isEmpty) {
      return 1000;
    }

    double max = 0;
    for (final MapEntry<String, double> entry in entries) {
      if (entry.value > max) {
        max = entry.value;
      }
    }

    return max * 1.2;
  }

  String _shortCategory(String value) {
    final String normalized = value.trim();
    if (normalized.length <= 8) {
      return normalized;
    }
    return '${normalized.substring(0, 8)}..';
  }

  Widget _deltaItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required bool positive,
  }) {
    return Row(
      children: <Widget>[
        CircleAvatar(
          radius: 13,
          backgroundColor: (positive ? Colors.green : Colors.red).withValues(alpha: 0.2),
          child: Icon(icon, size: 14, color: positive ? Colors.greenAccent : Colors.redAccent),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.bodySmall),
            Text(
              value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOutgoingMethodCircles(
    BuildContext context,
    List<FinanceTransaction> transactions,
  ) {
    final List<_PaymentMethodSpend> methods =
        _groupOutgoingByMethod(transactions);
    if (methods.isEmpty) {
      return Text(
        'No outgoing transactions yet.',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }

    return SizedBox(
      height: 98,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: methods.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (BuildContext context, int index) {
          final _PaymentMethodSpend method = methods[index];
          final Color accent = _paymentMethodColor(method.label);
          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              _openPaymentMethodSheet(
                context,
                method: method,
              );
            },
            child: SizedBox(
              width: 84,
              child: Column(
                children: <Widget>[
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withValues(alpha: 0.14),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          _paymentMethodIcon(method.label),
                          size: 18,
                          color: accent,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _compactInr(method.totalAmount),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: accent,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    method.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w600,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<_PaymentMethodSpend> _groupOutgoingByMethod(
    List<FinanceTransaction> transactions,
  ) {
    final Map<String, List<FinanceTransaction>> grouped =
        <String, List<FinanceTransaction>>{};

    for (final FinanceTransaction tx in transactions) {
      if (!tx.isExpense) {
        continue;
      }

      final String method = _paymentMethodLabel(tx);
      grouped.putIfAbsent(method, () => <FinanceTransaction>[]).add(tx);
    }

    final List<_PaymentMethodSpend> result = grouped.entries
        .map((MapEntry<String, List<FinanceTransaction>> entry) {
          final double total = entry.value.fold<double>(
            0,
            (double sum, FinanceTransaction tx) => sum + tx.amount,
          );
          return _PaymentMethodSpend(
            label: entry.key,
            transactions: entry.value,
            totalAmount: total,
          );
        })
        .toList(growable: false)
      ..sort((_PaymentMethodSpend a, _PaymentMethodSpend b) {
        return b.totalAmount.compareTo(a.totalAmount);
      });

    return result;
  }

  String _paymentMethodLabel(FinanceTransaction tx) {
    final String source = tx.source.toLowerCase();
    final String channel = tx.channel.toLowerCase();
    final String title = tx.title.toLowerCase();
    final String combined = '$source $channel $title';

    if (combined.contains('phonepe') || combined.contains('phone pe')) {
      return 'PhonePe';
    }
    if (combined.contains('gpay') ||
        combined.contains('googlepay') ||
        combined.contains('google pay')) {
      return 'Google Pay';
    }
    if (combined.contains('paytm')) {
      return 'Paytm';
    }
    if (combined.contains('amazon pay')) {
      return 'Amazon Pay';
    }
    if (combined.contains('bhim')) {
      return 'BHIM UPI';
    }
    if (combined.contains('cred')) {
      return 'NAVI';
    }
    if (combined.contains('freecharge')) {
      return 'Freecharge';
    }
    if (combined.contains('mobikwik')) {
      return 'MobiKwik';
    }
    if (combined.contains('cash')) {
      return 'Cash';
    }
    if (combined.contains('card') ||
        combined.contains('credit') ||
        combined.contains('debit')) {
      return 'Card';
    }
    if (combined.contains('bank') || combined.contains('transfer')) {
      return 'Bank';
    }
    if (combined.contains('upi')) {
      return 'UPI';
    }

    final String trimmedSource = tx.source.trim();
    if (trimmedSource.isNotEmpty && trimmedSource != 'manual') {
      return trimmedSource[0].toUpperCase() + trimmedSource.substring(1);
    }

    return 'Other';
  }

  IconData _paymentMethodIcon(String method) {
    final String normalized = method.toLowerCase();
    if (normalized.contains('phonepe')) {
      return Icons.account_balance_wallet_outlined;
    }
    if (normalized.contains('google')) {
      return Icons.payments_outlined;
    }
    if (normalized.contains('paytm')) {
      return Icons.qr_code_scanner_outlined;
    }
    if (normalized.contains('amazon')) {
      return Icons.shopping_bag_outlined;
    }
    if (normalized.contains('bhim')) {
      return Icons.account_balance_wallet_outlined;
    }
    if (normalized.contains('cred')) {
      return Icons.credit_score_outlined;
    }
    if (normalized.contains('cash')) {
      return Icons.currency_rupee;
    }
    if (normalized.contains('card')) {
      return Icons.credit_card_outlined;
    }
    if (normalized.contains('bank')) {
      return Icons.account_balance_outlined;
    }
    if (normalized.contains('upi')) {
      return Icons.swap_horiz_outlined;
    }
    return Icons.wallet_outlined;
  }

  Color _paymentMethodColor(String method) {
    final String normalized = method.toLowerCase();
    if (normalized.contains('phonepe')) {
      return const Color(0xFF5F259F);
    }
    if (normalized.contains('google')) {
      return const Color(0xFF1A73E8);
    }
    if (normalized.contains('paytm')) {
      return const Color(0xFF00BAF2);
    }
    if (normalized.contains('amazon')) {
      return const Color(0xFFFF9900);
    }
    if (normalized.contains('bhim')) {
      return const Color(0xFF2E7D32);
    }
    if (normalized.contains('cred')) {
      return const Color(0xFF263238);
    }
    if (normalized.contains('cash')) {
      return const Color(0xFF2E7D32);
    }
    if (normalized.contains('card')) {
      return const Color(0xFF8E24AA);
    }
    if (normalized.contains('bank')) {
      return const Color(0xFF1565C0);
    }
    if (normalized.contains('upi')) {
      return const Color(0xFFEF6C00);
    }
    return const Color(0xFF455A64);
  }

  String _compactInr(double amount) {
    if (amount >= 100000) {
      return 'Rs ${(amount / 100000).toStringAsFixed(1)}L';
    }
    if (amount >= 1000) {
      return 'Rs ${(amount / 1000).toStringAsFixed(1)}k';
    }
    return 'Rs ${amount.toStringAsFixed(0)}';
  }

  void _openPaymentMethodSheet(
    BuildContext context, {
    required _PaymentMethodSpend method,
  }) {
    final List<FinanceTransaction> sorted = List<FinanceTransaction>.from(
      method.transactions,
    )..sort((FinanceTransaction a, FinanceTransaction b) {
        return b.transactionAt.compareTo(a.transactionAt);
      });

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext context) {
        final Color accent = _paymentMethodColor(method.label);
        return FractionallySizedBox(
          heightFactor: 0.82,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: <Widget>[
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: accent.withValues(alpha: 0.14),
                      child: Icon(
                        _paymentMethodIcon(method.label),
                        size: 18,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            method.label,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: accent,
                                ),
                          ),
                          Text(
                            '${CurrencyFormatter.inr(method.totalAmount)} • ${sorted.length} outgoing transactions',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: sorted.isEmpty
                      ? const EmptyState(
                          title: 'No transactions found',
                          message: 'No outgoing data for this method yet.',
                          icon: Icons.receipt_long,
                        )
                      : ListView.separated(
                          itemCount: sorted.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (BuildContext context, int index) {
                            final FinanceTransaction tx = sorted[index];
                            return ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.arrow_downward, size: 16),
                              title: Text(tx.title),
                              subtitle: Text(
                                tx.category.toUpperCase(),
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                              trailing: Text(
                                '-${CurrencyFormatter.inr(tx.amount)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: accent,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _topSpendingsRow(
    BuildContext context,
    Map<String, double> categoryBreakdown, {
    required List<FinanceTransaction> transactions,
  }) {
    final List<MapEntry<String, double>> items = categoryBreakdown.entries.toList()
      ..sort((MapEntry<String, double> a, MapEntry<String, double> b) => b.value.compareTo(a.value));

    if (items.isEmpty) {
      return const EmptyState(
        title: 'No top spendings yet',
        message: 'Add expenses to see your top categories.',
        icon: Icons.local_offer_outlined,
      );
    }

    final double totalSpend = items.fold<double>(
      0,
      (double sum, MapEntry<String, double> item) => sum + item.value,
    );

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 8),
      itemBuilder: (BuildContext context, int index) {
        final MapEntry<String, double> entry = items[index];
        final List<FinanceTransaction> categoryTransactions = transactions
            .where(
              (FinanceTransaction tx) =>
                  tx.category.toLowerCase() == entry.key.toLowerCase(),
            )
            .toList(growable: false);
        final double sharePercent = totalSpend <= 0
            ? 0
            : (entry.value / totalSpend) * 100;

        return InkWell(
          onTap: () {
            _openCategorySpendingSheet(
              context,
              category: entry.key,
              amount: entry.value,
              sharePercent: sharePercent,
              transactions: categoryTransactions,
            );
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                  child: Icon(_categoryIcon(entry.key), size: 19),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        _displayCategory(entry.key),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${sharePercent.toStringAsFixed(1)}% of total spend',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      CurrencyFormatter.inr(entry.value),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${categoryTransactions.length} txns',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, size: 18),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openCategorySpendingSheet(
    BuildContext context, {
    required String category,
    required double amount,
    required double sharePercent,
    required List<FinanceTransaction> transactions,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.78,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: <Widget>[
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      child: Icon(_categoryIcon(category), size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            _displayCategory(category),
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          Text(
                            '${CurrencyFormatter.inr(amount)} • ${sharePercent.toStringAsFixed(1)}% of total',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: transactions.isEmpty
                      ? const EmptyState(
                          title: 'No transactions in this category',
                          message: 'Add transactions to see complete details.',
                          icon: Icons.receipt_long,
                        )
                      : ListView.separated(
                          itemCount: transactions.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (BuildContext context, int index) {
                            final FinanceTransaction tx = transactions[index];
                            return ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                tx.isExpense
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward,
                                size: 16,
                              ),
                              title: Text(tx.title),
                              subtitle: Text(
                                tx.source.toUpperCase(),
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                              trailing: Text(
                                '${tx.isExpense ? '-' : '+'}${CurrencyFormatter.inr(tx.amount)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: tx.isExpense
                                      ? Theme.of(context).colorScheme.error
                                      : Colors.green.shade700,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _displayCategory(String category) {
    if (category.isEmpty) {
      return 'Other';
    }
    return category[0].toUpperCase() + category.substring(1);
  }

  IconData _categoryIcon(String category) {
    final String normalized = category.toLowerCase();
    if (normalized.contains('food')) {
      return Icons.restaurant;
    }
    if (normalized.contains('rent') || normalized.contains('hostel')) {
      return Icons.home_outlined;
    }
    if (normalized.contains('utilit') || normalized.contains('bill')) {
      return Icons.bolt_outlined;
    }
    if (normalized.contains('education') || normalized.contains('book')) {
      return Icons.menu_book_outlined;
    }
    if (normalized.contains('health') || normalized.contains('medical')) {
      return Icons.health_and_safety_outlined;
    }
    if (normalized.contains('shop')) {
      return Icons.shopping_bag_outlined;
    }
    if (normalized.contains('travel')) {
      return Icons.directions_car_outlined;
    }
    if (normalized.contains('entertain')) {
      return Icons.movie_outlined;
    }
    if (normalized.contains('freelance') || normalized.contains('stipend')) {
      return Icons.work_outline;
    }
    return Icons.local_offer_outlined;
  }
}


class _AiStrategyCard extends StatelessWidget {
  const _AiStrategyCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 190,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                description,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

      ),
    );
  }
}

class _PaymentMethodSpend {
  const _PaymentMethodSpend({
    required this.label,
    required this.transactions,
    required this.totalAmount,
  });

  final String label;
  final List<FinanceTransaction> transactions;
  final double totalAmount;
}

class _HomeDetailsSheet extends StatelessWidget {
  const _HomeDetailsSheet({
    required this.snapshot,
    required this.transactions,
    required this.savingsGoals,
    required this.topic,
  });

  final DashboardSnapshot snapshot;
  final List<FinanceTransaction> transactions;
  final List<SavingsGoal> savingsGoals;
  final String topic;

  @override
  Widget build(BuildContext context) {
    final bool showAll = topic == 'all';
    bool showTopic(String value) => showAll || topic == value;

    final List<MapEntry<String, double>> categories =
        snapshot.categoryBreakdown.entries.toList()
          ..sort((MapEntry<String, double> a, MapEntry<String, double> b) {
            return b.value.compareTo(a.value);
          });

    final List<SavingsGoal> sortedGoals = List<SavingsGoal>.from(savingsGoals)
      ..sort((SavingsGoal a, SavingsGoal b) => b.updatedAt.compareTo(a.updatedAt));

    final List<String> aiSuggestions = _buildAiSpendSuggestions(
      snapshot: snapshot,
      categories: categories,
    );

    final Iterable<FinanceTransaction> sectionTransactions = showAll
        ? transactions
        : transactions.where((FinanceTransaction tx) => tx.isExpense);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: <Widget>[
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ListView(
              children: <Widget>[
                if (showTopic('overview')) ...<Widget>[
                  _DetailBlock(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        _MiniMetric(
                          label: 'Total Balance',
                          value: CurrencyFormatter.inr(snapshot.totalBalance),
                        ),
                        _MiniMetric(
                          label: 'Total Saved',
                          value: CurrencyFormatter.inr(snapshot.totalSavings),
                        ),
                        _MiniMetric(
                          label: 'Safe To Spend',
                          value: CurrencyFormatter.inr(snapshot.safeToSpend),
                        ),
                        _MiniMetric(
                          label: 'Weekly Spend',
                          value: CurrencyFormatter.inr(snapshot.weeklySpend),
                        ),
                        _MiniMetric(
                          label: 'Burn Rate',
                          value: CurrencyFormatter.inr(snapshot.burnRate),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (showAll) ...<Widget>[
                  _DetailBlock(
                    child: categories.isEmpty
                        ? const Text('No category data yet.')
                        : Column(
                            children: categories.map((MapEntry<String, double> e) {
                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.bar_chart, size: 18),
                                title: Text(
                                  e.key[0].toUpperCase() + e.key.substring(1),
                                ),
                                trailing: Text(
                                  CurrencyFormatter.inr(e.value),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              );
                            }).toList(growable: false),
                          ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (showTopic('savings')) ...<Widget>[
                  _DetailBlock(
                    child: sortedGoals.isEmpty
                        ? const Text('No savings history found.')
                        : Column(
                            children: sortedGoals.map((SavingsGoal goal) {
                              final double progress = goal.progress * 100;
                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(
                                  goal.status == GoalStatus.achieved
                                      ? Icons.emoji_events
                                      : Icons.savings_outlined,
                                  size: 18,
                                ),
                                title: Text(goal.title),
                                subtitle: Text(
                                  'Saved ${CurrencyFormatter.inr(goal.savedAmount)} / ${CurrencyFormatter.inr(goal.targetAmount)}',
                                ),
                                trailing: Text(
                                  '${progress.toStringAsFixed(0)}%',
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                              );
                            }).toList(growable: false),
                          ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (showTopic('burn_rate') || showAll) ...<Widget>[
                  _DetailBlock(
                    child: snapshot.monthlySpendEntries.isEmpty
                        ? const Text('Not enough monthly trend data yet.')
                        : Column(
                            children: snapshot.monthlySpendEntries
                                .map((MapEntry<String, double> e) {
                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text(e.key),
                                trailing: Text(
                                  CurrencyFormatter.inr(e.value),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              );
                            }).toList(growable: false),
                          ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (showTopic('safe_to_spend') || showAll) ...<Widget>[
                  _DetailBlock(
                    child: Column(
                      children: aiSuggestions.map((String tip) {
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.auto_awesome, size: 18),
                          title: Text(tip),
                        );
                      }).toList(growable: false),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (showTopic('weekly_spend') || showAll) ...<Widget>[
                  _DetailBlock(
                    child: sectionTransactions.isEmpty
                        ? const Text('No transactions found.')
                        : Column(
                            children: sectionTransactions
                                .take(12)
                                .map((FinanceTransaction tx) {
                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text(tx.title),
                                subtitle: Text(tx.category.toUpperCase()),
                                trailing: Text(
                                  '${tx.isExpense ? '-' : '+'}${CurrencyFormatter.inr(tx.amount)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: tx.isExpense
                                        ? Theme.of(context).colorScheme.error
                                        : Colors.green.shade700,
                                  ),
                                ),
                              );
                            }).toList(growable: false),
                          ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<String> _buildAiSpendSuggestions({
    required DashboardSnapshot snapshot,
    required List<MapEntry<String, double>> categories,
  }) {
    final List<String> suggestions = <String>[];

    double categoryAmount(String keyword) {
      for (final MapEntry<String, double> item in categories) {
        if (item.key.toLowerCase().contains(keyword)) {
          return item.value;
        }
      }
      return 0;
    }

    final double foodSpend = categoryAmount('food');
    final double shoppingSpend = categoryAmount('shop');
    final double travelSpend = categoryAmount('travel');
    final double utilitiesSpend = categoryAmount('utilit');

    if (snapshot.safeToSpend <= 0) {
      suggestions.add(
        'Pause non-essential spending for 3 to 5 days and prioritize rent, food, utilities.',
      );
    } else {
      suggestions.add(
        'Keep your optional spend under ${CurrencyFormatter.inr(snapshot.safeToSpend * 0.25)} this week to stay safe.',
      );
    }

    if (foodSpend > 0) {
      final double saveAmount = foodSpend * 0.25;
      suggestions.add(
        'Food tip: Cook 3 meals at home weekly instead of ordering. You can save about ${CurrencyFormatter.inr(saveAmount)} per month.',
      );
    }

    if (shoppingSpend > 0) {
      final double saveAmount = shoppingSpend * 0.15;
      suggestions.add(
        'Shopping tip: Use a 24-hour wait rule before non-essential buys. You can save around ${CurrencyFormatter.inr(saveAmount)} monthly.',
      );
    }

    if (travelSpend > 0) {
      final double saveAmount = travelSpend * 0.2;
      suggestions.add(
        'Travel tip: Club trips and prefer metro/bus for short routes. Potential saving is about ${CurrencyFormatter.inr(saveAmount)} monthly.',
      );
    }

    if (utilitiesSpend > 0) {
      final double saveAmount = utilitiesSpend * 0.1;
      suggestions.add(
        'Utilities tip: Track electricity and mobile data use weekly. You can save nearly ${CurrencyFormatter.inr(saveAmount)} each month.',
      );
    }

    if (snapshot.isMonthlySpendUp) {
      suggestions.add(
        'Your spending is trending up. Set a hard daily cap near ${CurrencyFormatter.inr((snapshot.safeToSpend <= 0 ? snapshot.weeklySpend : snapshot.safeToSpend) / 7)}.',
      );
    }

    if (categories.isNotEmpty) {
      final MapEntry<String, double> top = categories.first;
      suggestions.add(
        'Highest spend is ${top.key}. Try to reduce this by 10% this month and move it to savings.',
      );
    }

    if (suggestions.length < 3) {
      suggestions.add(
        'Before each purchase, ask FinMate if it fits your weekly plan.',
      );
    }

    return suggestions.take(6).toList(growable: false);
  }
}

class _DetailBlock extends StatelessWidget {
  const _DetailBlock({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          child,
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 156,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.38,
            ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}
