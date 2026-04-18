import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:student_fin_os/core/utils/currency_formatter.dart';
import 'package:student_fin_os/core/widgets/empty_state.dart';
import 'package:student_fin_os/core/widgets/section_header.dart';
import 'package:student_fin_os/models/ai_insight.dart';
import 'package:student_fin_os/models/dashboard_snapshot.dart';
import 'package:student_fin_os/models/finance_enums.dart';
import 'package:student_fin_os/models/finance_transaction.dart';
import 'package:student_fin_os/providers/cash_flow_providers.dart';
import 'package:student_fin_os/providers/dashboard_providers.dart';
import 'package:student_fin_os/providers/insights_providers.dart';

enum _InsightFilter {
  all,
  critical,
  warning,
  info,
}

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  _InsightFilter _filter = _InsightFilter.all;
  double _assumedAnnualReturn = 12;
  int _sipYears = 10;
  int _selectedSipAmount = 2000;

  static const List<int> _sipScenarioAmounts = <int>[
    500,
    1000,
    2000,
    5000,
    10000,
    15000,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref.read(insightsControllerProvider.notifier).refreshRuleBasedInsights();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Financial Insights'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Feed'),
              Tab(text: 'Budget Options'),
              Tab(text: 'Saving Options'),
              Tab(text: 'Investing'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildFeedTab(context),
            _buildBudgetTab(context),
            _buildSavingsTab(context),
            _buildInvestingTab(context),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedTab(BuildContext context) {
    final List<AiInsight> insights = ref.watch(insightsFeedProvider).value ?? const <AiInsight>[];
    final List<AiInsight> automated = ref.watch(automatedInsightsProvider);
    final DateTime? lowBalanceDate = ref.watch(predictedLowBalanceDateProvider);
    final List<AiInsight> stableInsights = _dedupeInsights(insights);

    final List<AiInsight> filtered = stableInsights.where((AiInsight insight) {
      switch (_filter) {
        case _InsightFilter.all:
          return true;
        case _InsightFilter.critical:
          return insight.severity == InsightSeverity.critical;
        case _InsightFilter.warning:
          return insight.severity == InsightSeverity.warning;
        case _InsightFilter.info:
          return insight.severity == InsightSeverity.info;
      }
    }).toList();

      final int criticalCount = stableInsights
        .where((AiInsight insight) => insight.severity == InsightSeverity.critical)
        .length;
      final int warningCount = stableInsights
        .where((AiInsight insight) => insight.severity == InsightSeverity.warning)
        .length;
      final int infoCount = stableInsights
        .where((AiInsight insight) => insight.severity == InsightSeverity.info)
        .length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _statusCard(
                context,
                label: 'Urgent',
                value: '$criticalCount',
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _statusCard(
                context,
                label: 'Heads-up',
                value: '$warningCount',
                color: Colors.orangeAccent,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _statusCard(
                context,
                label: 'FYI',
                value: '$infoCount',
                color: Colors.blueAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            const Expanded(
              child: SectionHeader(
                title: 'Money Feed',
                subtitle: 'Clear alerts + what to do next',
              ),
            ),
            FilledButton.icon(
              onPressed: () {
                ref.read(insightsControllerProvider.notifier).refreshRuleBasedInsights();
              },
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Sync Feed'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Card(
          child: ListTile(
            leading: const Icon(Icons.timeline),
            title: const Text('Balance runway'),
            subtitle: Text(
              lowBalanceDate == null
                  ? 'You look stable for the next 14 days.'
                  : 'At current pace, balance may get tight around ${DateFormat('dd MMM').format(lowBalanceDate)}.',
            ),
          ),
        ),
        if (automated.isNotEmpty) ...<Widget>[
          const SizedBox(height: 10),
          const SectionHeader(
            title: 'Auto Recommendations',
            subtitle: 'Generated from your latest dashboard and transaction data',
          ),
          const SizedBox(height: 8),
          ...automated.take(3).map((AiInsight insight) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(
                  _iconForSeverity(insight.severity),
                  color: _colorForSeverity(insight.severity),
                ),
                title: Text(insight.title),
                subtitle: Text(insight.message),
              ),
            );
          }),
        ],
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: <Widget>[
              _filterChip('All', _InsightFilter.all),
              const SizedBox(width: 8),
              _filterChip('Urgent', _InsightFilter.critical),
              const SizedBox(width: 8),
              _filterChip('Heads-up', _InsightFilter.warning),
              const SizedBox(width: 8),
              _filterChip('FYI', _InsightFilter.info),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (filtered.isEmpty)
          const EmptyState(
            title: 'No insights in this filter',
            message: 'Insights will appear automatically from your latest data.',
            icon: Icons.lightbulb,
          )
        else
          ...filtered.map((AiInsight insight) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(
                          _iconForSeverity(insight.severity),
                          color: _colorForSeverity(insight.severity),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            insight.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Text(DateFormat('dd MMM').format(insight.createdAt)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(insight.message),
                    const SizedBox(height: 8),
                    Text(
                      _actionHint(insight.severity),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  List<AiInsight> _dedupeInsights(List<AiInsight> items) {
    final Map<String, AiInsight> byKey = <String, AiInsight>{};
    for (final AiInsight insight in items) {
      final String key = '${insight.severity.name}::${insight.title.toLowerCase()}';
      final AiInsight? existing = byKey[key];
      if (existing == null || insight.createdAt.isAfter(existing.createdAt)) {
        byKey[key] = insight;
      }
    }
    final List<AiInsight> deduped = byKey.values.toList(growable: false)
      ..sort((AiInsight a, AiInsight b) => b.createdAt.compareTo(a.createdAt));
    return deduped;
  }

  Widget _buildBudgetTab(BuildContext context) {
    final DashboardSnapshot snapshot = ref.watch(dashboardSnapshotProvider);
    final List<FinanceTransaction> transactions =
        ref.watch(transactionsProvider).value ?? const <FinanceTransaction>[];
    final DateTime now = DateTime.now();
    final List<FinanceTransaction> monthTransactions = _monthTransactions(
      transactions,
      now,
    );

    final double monthIncome = _monthIncome(monthTransactions);
    final double monthExpense = _monthExpense(monthTransactions);
    final int daysInMonth = _daysInMonth(now);
    final int elapsedDays = now.day.clamp(1, daysInMonth);
    final double avgDailySpend =
        elapsedDays == 0 ? 0 : monthExpense / elapsedDays;
    final double forecastSpend = avgDailySpend * daysInMonth;

    final List<MapEntry<String, double>> topCategories = _topExpenseCategories(
      monthTransactions,
      5,
    );
    final String narrative = _spendingNarrative(
      monthIncome: monthIncome,
      monthExpense: monthExpense,
      forecastSpend: forecastSpend,
      safeToSpend: snapshot.safeToSpend,
      monthlyTrendPercent: snapshot.monthlyTrendPercent,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        const SectionHeader(
          title: 'Spending Analysis',
          subtitle: 'Real-time monthly spend + projected month-end behavior.',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _metricCard(
              context,
              label: 'This Month Spend',
              value: CurrencyFormatter.inr(monthExpense),
              icon: Icons.payments_outlined,
            ),
            _metricCard(
              context,
              label: 'This Month Income',
              value: CurrencyFormatter.inr(monthIncome),
              icon: Icons.account_balance_wallet_outlined,
            ),
            _metricCard(
              context,
              label: 'Month-End Estimate',
              value: CurrencyFormatter.inr(forecastSpend),
              icon: Icons.timeline_outlined,
            ),
            _metricCard(
              context,
              label: 'Safe To Spend',
              value: CurrencyFormatter.inr(snapshot.safeToSpend),
              icon: Icons.shield_outlined,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              narrative,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const SectionHeader(
          title: 'Top Spend Categories',
          subtitle: 'Live category split for the current month.',
        ),
        const SizedBox(height: 10),
        if (topCategories.isEmpty)
          const Card(
            child: ListTile(
              leading: Icon(Icons.bar_chart_outlined),
              title: Text('No monthly spending data yet.'),
            ),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
              child: SizedBox(
                height: 220,
                child: BarChart(
                  BarChartData(
                    maxY: topCategories.first.value * 1.2,
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            final int idx = value.toInt();
                            if (idx < 0 || idx >= topCategories.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                _shortCategory(topCategories[idx].key),
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    barGroups: _barGroupsForCategories(topCategories),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSavingsTab(BuildContext context) {
    final DashboardSnapshot snapshot = ref.watch(dashboardSnapshotProvider);
    final List<FinanceTransaction> transactions =
        ref.watch(transactionsProvider).value ?? const <FinanceTransaction>[];
    final DateTime now = DateTime.now();
    final List<FinanceTransaction> monthTransactions = _monthTransactions(
      transactions,
      now,
    );

    final double monthExpense = _monthExpense(monthTransactions);
    final double baselineMonthlyExpense =
        monthExpense > 0 ? monthExpense : snapshot.monthlySpend;
    final double emergencyTarget = baselineMonthlyExpense * 6;
    final double currentReserve = math.max(snapshot.totalBalance, 0);
    final double reserveGap = math.max(emergencyTarget - currentReserve, 0);
    final double reserveProgress = emergencyTarget <= 0
        ? 1
        : (currentReserve / emergencyTarget).clamp(0, 1).toDouble();
    final double suggestedMonthlyReserve = reserveGap <= 0
        ? 0
        : math.max(500, reserveGap / 12);

    final List<int> reserveScenarios = <int>[1000, 2000, 5000, 10000];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        const SectionHeader(
          title: 'Savings Readiness',
          subtitle: 'How much you should save before aggressive investing.',
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Emergency Fund Progress',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Current reserve: ${CurrencyFormatter.inr(currentReserve)}\n'
                  'Target (6 months expense): ${CurrencyFormatter.inr(emergencyTarget)}\n'
                  'Gap: ${CurrencyFormatter.inr(reserveGap)}',
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(value: reserveProgress),
                const SizedBox(height: 8),
                Text(
                  reserveGap <= 0
                      ? 'Great. You have enough reserve to start higher SIP amounts safely.'
                      : 'Suggested reserve build amount: ${CurrencyFormatter.inr(suggestedMonthlyReserve)} per month.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const SectionHeader(
          title: 'Reserve Build Scenarios',
          subtitle: 'Estimated time to close reserve gap for multiple monthly amounts.',
        ),
        const SizedBox(height: 8),
        ...reserveScenarios.map((int amount) {
          final int months = reserveGap <= 0 ? 0 : (reserveGap / amount).ceil();
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.savings_outlined),
              title: Text('Save ${CurrencyFormatter.inr(amount.toDouble())} per month'),
              subtitle: Text(
                months == 0
                    ? 'Reserve target already covered.'
                    : 'Estimated completion in about $months month${months == 1 ? '' : 's'}.',
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildInvestingTab(BuildContext context) {
    final DashboardSnapshot snapshot = ref.watch(dashboardSnapshotProvider);
    final List<FinanceTransaction> transactions =
        ref.watch(transactionsProvider).value ?? const <FinanceTransaction>[];
    final DateTime now = DateTime.now();
    final List<FinanceTransaction> monthTransactions = _monthTransactions(
      transactions,
      now,
    );

    final double monthIncome = _monthIncome(monthTransactions);
    final double monthExpense = _monthExpense(monthTransactions);
    final double monthNet = monthIncome - monthExpense;
    final double suggestedSipLow = monthNet <= 0 ? 0 : monthNet * 0.15;
    final double suggestedSipHigh = monthNet <= 0 ? 0 : monthNet * 0.35;

    final List<_SipProjection> projections = _sipScenarioAmounts
        .map((int amount) => _sipProjection(
              monthlyAmount: amount.toDouble(),
              years: _sipYears,
              annualReturn: _assumedAnnualReturn,
            ))
        .toList(growable: false);

    final _SipProjection selected = _sipProjection(
      monthlyAmount: _selectedSipAmount.toDouble(),
      years: _sipYears,
      annualReturn: _assumedAnnualReturn,
    );

    final String narrative = _sipNarrative(
      monthNet: monthNet,
      suggestedSipLow: suggestedSipLow,
      suggestedSipHigh: suggestedSipHigh,
      selected: selected,
      safeToSpend: snapshot.safeToSpend,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        const SectionHeader(
          title: 'Stock SIP Planner',
          subtitle: 'Real-time affordability + estimated market returns.',
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Live Monthly Cashflow',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Income: ${CurrencyFormatter.inr(monthIncome)}\n'
                  'Spend: ${CurrencyFormatter.inr(monthExpense)}\n'
                  'Net: ${CurrencyFormatter.inr(monthNet)}',
                ),
                const SizedBox(height: 8),
                Text(
                  monthNet <= 0
                      ? 'You are currently cashflow-negative. Reduce spending first, then start SIP at a small amount.'
                      : 'Suggested SIP range from current cashflow: ${CurrencyFormatter.inr(suggestedSipLow)} to ${CurrencyFormatter.inr(suggestedSipHigh)} per month.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Assumptions',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Expected annual return: ${_assumedAnnualReturn.toStringAsFixed(1)}%',
                ),
                Slider(
                  value: _assumedAnnualReturn,
                  min: 8,
                  max: 18,
                  divisions: 20,
                  label: '${_assumedAnnualReturn.toStringAsFixed(1)}%',
                  onChanged: (double value) {
                    setState(() {
                      _assumedAnnualReturn = value;
                    });
                  },
                ),
                Text('Investment horizon: $_sipYears years'),
                Slider(
                  value: _sipYears.toDouble(),
                  min: 1,
                  max: 25,
                  divisions: 24,
                  label: '$_sipYears years',
                  onChanged: (double value) {
                    setState(() {
                      _sipYears = value.round();
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: _sipScenarioAmounts.map((int amount) {
            return ChoiceChip(
              selected: _selectedSipAmount == amount,
              label: Text(CurrencyFormatter.inr(amount.toDouble())),
              onSelected: (_) {
                setState(() {
                  _selectedSipAmount = amount;
                });
              },
            );
          }).toList(growable: false),
        ),
        const SizedBox(height: 10),
        Card(
          child: ListTile(
            leading: const Icon(Icons.calculate_outlined),
            title: Text('SIP ${CurrencyFormatter.inr(selected.monthlyAmount)} for $_sipYears years'),
            subtitle: Text(
              'Invested: ${CurrencyFormatter.inr(selected.totalInvested)}\n'
              'Estimated corpus: ${CurrencyFormatter.inr(selected.estimatedCorpus)}\n'
              'Estimated gain: ${CurrencyFormatter.inr(selected.estimatedGain)}',
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
            child: SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: _sipYears.toDouble(),
                  minY: 0,
                  maxY: selected.estimatedCorpus * 1.15,
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: _sipYears <= 6 ? 1 : 2,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          return Text(
                            '${value.toInt()}y',
                            style: Theme.of(context).textTheme.labelSmall,
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: <LineChartBarData>[
                    LineChartBarData(
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      spots: _sipGrowthSeries(
                        monthlyAmount: selected.monthlyAmount,
                        years: _sipYears,
                        annualReturn: _assumedAnnualReturn,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
            child: SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  maxY: projections.last.estimatedCorpus * 1.2,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          final int idx = value.toInt();
                          if (idx < 0 || idx >= projections.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              '${(projections[idx].monthlyAmount / 1000).toStringAsFixed(0)}k',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: _barGroupsForSip(projections),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              narrative,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      ],
    );
  }

  Widget _metricCard(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      width: 165,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _barGroupsForCategories(
    List<MapEntry<String, double>> categories,
  ) {
    final List<Color> colors = <Color>[
      Colors.indigo,
      Colors.teal,
      Colors.orange,
      Colors.pink,
      Colors.green,
    ];

    return List<BarChartGroupData>.generate(categories.length, (int index) {
      return BarChartGroupData(
        x: index,
        barRods: <BarChartRodData>[
          BarChartRodData(
            toY: categories[index].value,
            color: colors[index % colors.length],
            width: 16,
            borderRadius: BorderRadius.circular(5),
          ),
        ],
      );
    });
  }

  List<BarChartGroupData> _barGroupsForSip(List<_SipProjection> projections) {
    return List<BarChartGroupData>.generate(projections.length, (int index) {
      final _SipProjection projection = projections[index];
      return BarChartGroupData(
        x: index,
        barRods: <BarChartRodData>[
          BarChartRodData(
            toY: projection.estimatedCorpus,
            color: projection.monthlyAmount == _selectedSipAmount
                ? Colors.deepPurple
                : Colors.deepPurple.withValues(alpha: 0.45),
            width: 16,
            borderRadius: BorderRadius.circular(5),
          ),
        ],
      );
    });
  }

  List<FinanceTransaction> _monthTransactions(
    List<FinanceTransaction> transactions,
    DateTime now,
  ) {
    return transactions.where((FinanceTransaction tx) {
      return tx.transactionAt.year == now.year && tx.transactionAt.month == now.month;
    }).toList(growable: false);
  }

  double _monthIncome(List<FinanceTransaction> transactions) {
    return transactions
        .where((FinanceTransaction tx) => tx.isIncome)
        .fold<double>(0, (double sum, FinanceTransaction tx) => sum + tx.amount);
  }

  double _monthExpense(List<FinanceTransaction> transactions) {
    return transactions
        .where((FinanceTransaction tx) => tx.isExpense)
        .fold<double>(0, (double sum, FinanceTransaction tx) => sum + tx.amount);
  }

  int _daysInMonth(DateTime date) {
    final DateTime firstDayThisMonth = DateTime(date.year, date.month, 1);
    final DateTime firstDayNextMonth = DateTime(
      firstDayThisMonth.year,
      firstDayThisMonth.month + 1,
      1,
    );
    return firstDayNextMonth.subtract(const Duration(days: 1)).day;
  }

  List<MapEntry<String, double>> _topExpenseCategories(
    List<FinanceTransaction> monthTransactions,
    int limit,
  ) {
    final Map<String, double> categoryTotals = <String, double>{};
    for (final FinanceTransaction tx in monthTransactions) {
      if (!tx.isExpense) {
        continue;
      }
      categoryTotals.update(
        tx.category,
        (double value) => value + tx.amount,
        ifAbsent: () => tx.amount,
      );
    }

    final List<MapEntry<String, double>> entries = categoryTotals.entries.toList()
      ..sort((MapEntry<String, double> a, MapEntry<String, double> b) {
        return b.value.compareTo(a.value);
      });
    return entries.take(limit).toList(growable: false);
  }

  _SipProjection _sipProjection({
    required double monthlyAmount,
    required int years,
    required double annualReturn,
  }) {
    final int months = years * 12;
    final double monthlyRate = annualReturn / 100 / 12;
    final double invested = monthlyAmount * months;

    final double corpus;
    if (monthlyRate <= 0) {
      corpus = invested;
    } else {
      final num factor = math.pow(1 + monthlyRate, months);
      corpus = monthlyAmount * (((factor - 1) / monthlyRate) * (1 + monthlyRate));
    }

    return _SipProjection(
      monthlyAmount: monthlyAmount,
      totalInvested: invested,
      estimatedCorpus: corpus,
      estimatedGain: corpus - invested,
    );
  }

  List<FlSpot> _sipGrowthSeries({
    required double monthlyAmount,
    required int years,
    required double annualReturn,
  }) {
    final List<FlSpot> spots = <FlSpot>[];
    for (int year = 0; year <= years; year++) {
      final _SipProjection projection = _sipProjection(
        monthlyAmount: monthlyAmount,
        years: year,
        annualReturn: annualReturn,
      );
      spots.add(FlSpot(year.toDouble(), projection.estimatedCorpus));
    }
    return spots;
  }

  String _shortCategory(String category) {
    if (category.length <= 8) {
      return category;
    }
    return '${category.substring(0, 8)}..';
  }

  String _spendingNarrative({
    required double monthIncome,
    required double monthExpense,
    required double forecastSpend,
    required double safeToSpend,
    required double monthlyTrendPercent,
  }) {
    final String trendText = monthlyTrendPercent > 0
        ? 'Spending is up by ${monthlyTrendPercent.toStringAsFixed(1)}% vs last month.'
        : 'Spending is controlled at ${monthlyTrendPercent.abs().toStringAsFixed(1)}% lower than last month.';

    final String balanceText = monthIncome >= monthExpense
        ? 'You are within your monthly cashflow limit.'
        : 'You are overspending this month and should trim discretionary categories.';

    final String safeText = safeToSpend > 0
        ? 'You can still spend about ${CurrencyFormatter.inr(safeToSpend)} safely.'
        : 'Safe-to-spend is exhausted, so avoid fresh optional expenses.';

    return '$trendText $balanceText At this pace, month-end spend may close near '
        '${CurrencyFormatter.inr(forecastSpend)}. $safeText';
  }

  String _sipNarrative({
    required double monthNet,
    required double suggestedSipLow,
    required double suggestedSipHigh,
    required _SipProjection selected,
    required double safeToSpend,
  }) {
    if (monthNet <= 0) {
      return 'You are currently negative on monthly net cashflow. Reduce fixed and impulse spends first, '
          'then start with a small SIP like ${CurrencyFormatter.inr(500)} and scale once monthly net turns positive.';
    }

    final String range =
        '${CurrencyFormatter.inr(suggestedSipLow)} to ${CurrencyFormatter.inr(suggestedSipHigh)}';
    final String affordability = selected.monthlyAmount <= suggestedSipHigh
        ? 'The selected SIP is inside your current affordability range.'
        : 'The selected SIP is higher than the recommended safe range for current cashflow.';
    final String safeNote = safeToSpend > 0
        ? 'Keep weekly optional spends below ${CurrencyFormatter.inr(safeToSpend * 0.25)} to sustain this SIP.'
        : 'Stabilize weekly spending first before increasing SIP commitments.';

    return 'Based on live income and spend, your current monthly SIP range is $range. '
        '$affordability Over $_sipYears years at ${_assumedAnnualReturn.toStringAsFixed(1)}% assumed annual return, '
        'the selected plan may grow to ${CurrencyFormatter.inr(selected.estimatedCorpus)} '
        'on an invested amount of ${CurrencyFormatter.inr(selected.totalInvested)}. $safeNote';
  }

  Widget _statusCard(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: <Widget>[
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
          ),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }

  Widget _filterChip(String label, _InsightFilter value) {
    final bool selected = _filter == value;
    return FilterChip(
      selected: selected,
      label: Text(label),
      onSelected: (bool _) {
        setState(() {
          _filter = value;
        });
      },
    );
  }

  String _actionHint(InsightSeverity severity) {
    switch (severity) {
      case InsightSeverity.critical:
        return 'Action: Pause non-essential spending today.';
      case InsightSeverity.warning:
        return 'Action: Tighten this week budget slightly.';
      case InsightSeverity.info:
        return 'Action: Keep this habit going.';
    }
  }

  IconData _iconForSeverity(InsightSeverity severity) {
    switch (severity) {
      case InsightSeverity.info:
        return Icons.info;
      case InsightSeverity.warning:
        return Icons.warning_amber;
      case InsightSeverity.critical:
        return Icons.error_outline;
    }
  }

  Color _colorForSeverity(InsightSeverity severity) {
    switch (severity) {
      case InsightSeverity.info:
        return Colors.lightBlueAccent;
      case InsightSeverity.warning:
        return Colors.amberAccent;
      case InsightSeverity.critical:
        return Colors.redAccent;
    }
  }
}

class _SipProjection {
  const _SipProjection({
    required this.monthlyAmount,
    required this.totalInvested,
    required this.estimatedCorpus,
    required this.estimatedGain,
  });

  final double monthlyAmount;
  final double totalInvested;
  final double estimatedCorpus;
  final double estimatedGain;
}
