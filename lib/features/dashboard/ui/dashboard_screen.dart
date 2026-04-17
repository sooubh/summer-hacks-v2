import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_fin_os/core/utils/currency_formatter.dart';
import 'package:student_fin_os/core/widgets/empty_state.dart';
import 'package:student_fin_os/core/widgets/metric_card.dart';
import 'package:student_fin_os/core/widgets/section_header.dart';
import 'package:student_fin_os/models/account.dart';
import 'package:student_fin_os/models/finance_transaction.dart';
import 'package:student_fin_os/providers/dashboard_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(dashboardSnapshotProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final List<FinanceTransaction> txList = snapshot.unifiedTransactions;

    return SafeArea(
      child: CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Unified Platform',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'One clean financial view across all your accounts.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Container(
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
                        Text('Total Balance', style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyFormatter.inr(snapshot.totalBalance),
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            _deltaItem(
                              context,
                              icon: Icons.arrow_upward,
                              title: 'Income',
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
                              title: 'Spent',
                              value: CurrencyFormatter.inr(snapshot.monthlySpend),
                              positive: false,
                            ),
                          ],
                        ),
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
                      MetricCard(
                        label: 'Total balance',
                        value: CurrencyFormatter.inr(snapshot.totalBalance),
                        gradient: const <Color>[Color(0xFF8ABF9E), Color(0xFF68A57F)],
                      ),
                      MetricCard(
                        label: 'Safe to spend',
                        value: CurrencyFormatter.inr(snapshot.safeToSpend),
                        gradient: const <Color>[Color(0xFF8CB6D9), Color(0xFF6A9BC8)],
                      ),
                      MetricCard(
                        label: 'Weekly spend',
                        value: CurrencyFormatter.inr(snapshot.weeklySpend),
                        gradient: const <Color>[Color(0xFFC6B4DF), Color(0xFFAA93CE)],
                      ),
                      MetricCard(
                        label: 'Burn rate/day',
                        value: CurrencyFormatter.inr(snapshot.burnRate),
                        gradient: const <Color>[Color(0xFFE8C59A), Color(0xFFD9AD74)],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const SectionHeader(
                    title: 'Connected Accounts',
                    subtitle: 'Bank + UPI + cash balances',
                  ),
                  const SizedBox(height: 10),
                  accountsAsync.when(
                    data: (List<Account> accounts) {
                      if (accounts.isEmpty) {
                        return const EmptyState(
                          title: 'No accounts yet',
                          message: 'Seed or create accounts to view unified balances.',
                          icon: Icons.account_balance_wallet,
                        );
                      }
                      return Column(
                        children: accounts.map((Account item) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Icon(_iconForAccountType(item.accountType)),
                              ),
                              title: Text(item.name),
                              subtitle: Text(item.provider ?? 'wallet'),
                              trailing: Text(
                                CurrencyFormatter.inr(item.balance),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (Object error, StackTrace stackTrace) => Text('Error: $error'),
                  ),
                  const SizedBox(height: 18),
                  const SectionHeader(
                    title: 'Monthly Spending Trend',
                    subtitle: 'Month-over-month analysis',
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
                                ? 'No previous month baseline yet'
                                : snapshot.isMonthlySpendUp
                                    ? 'Spending increased by ${snapshot.monthlyTrendPercent.abs().toStringAsFixed(1)}%'
                                    : 'Spending decreased by ${snapshot.monthlyTrendPercent.abs().toStringAsFixed(1)}%',
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
                                ? const EmptyState(
                                    title: 'Not enough monthly data',
                                    message: 'Generate or add transactions to visualize spend trend.',
                                    icon: Icons.bar_chart,
                                  )
                                : BarChart(
                                    BarChartData(
                                      barGroups: _buildMonthlyBars(snapshot.monthlySpendEntries),
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
                                                  _shortMonth(snapshot.monthlySpendEntries[idx].key),
                                                  style: Theme.of(context).textTheme.bodySmall,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const SectionHeader(
                    title: 'Category Split (30d)',
                    subtitle: 'Spending by category',
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 220,
                    child: snapshot.categoryBreakdown.isEmpty
                        ? const EmptyState(
                            title: 'No category data yet',
                            message: 'Add transactions to unlock category insights.',
                            icon: Icons.pie_chart,
                          )
                        : PieChart(
                            PieChartData(
                              centerSpaceRadius: 50,
                              sectionsSpace: 2,
                              sections: _buildCategorySections(snapshot.categoryBreakdown),
                            ),
                          ),
                  ),
                  const SizedBox(height: 18),
                  const SectionHeader(
                    title: 'Recent Activity',
                    subtitle: 'Latest transactions',
                  ),
                  const SizedBox(height: 8),
                  if (txList.isEmpty)
                    const EmptyState(
                      title: 'No transactions found',
                      message: 'Add your first expense or income to start tracking.',
                      icon: Icons.receipt_long,
                    )
                  else
                    ...txList.take(6).map((FinanceTransaction tx) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            tx.isExpense ? Icons.south_west : Icons.north_east,
                            color: tx.isExpense
                                ? Theme.of(context).colorScheme.secondary
                                : Theme.of(context).colorScheme.primary,
                          ),
                          title: Text(tx.title),
                          subtitle: Text(tx.category),
                          trailing: Text(
                            '${tx.isExpense ? '-' : '+'}${CurrencyFormatter.inr(tx.amount)}',
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

  List<BarChartGroupData> _buildMonthlyBars(List<MapEntry<String, double>> entries) {
    return List<BarChartGroupData>.generate(entries.length, (int index) {
      final MapEntry<String, double> entry = entries[index];
      return BarChartGroupData(
        x: index,
        barRods: <BarChartRodData>[
          BarChartRodData(
            toY: entry.value,
            width: 16,
            borderRadius: BorderRadius.circular(4),
            color: const Color(0xFF4AA8FF),
          ),
        ],
      );
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

  List<PieChartSectionData> _buildCategorySections(Map<String, double> input) {
    final List<Color> colors = <Color>[
      const Color(0xFF2AE4C9),
      const Color(0xFFFF7D66),
      const Color(0xFF4AA8FF),
      const Color(0xFFE2B93B),
      const Color(0xFF76E06E),
      const Color(0xFFF05E89),
    ];

    int index = 0;
    return input.entries.map((MapEntry<String, double> entry) {
      final PieChartSectionData section = PieChartSectionData(
        value: entry.value,
        title: entry.key,
        radius: 60,
        color: colors[index % colors.length],
        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      );
      index++;
      return section;
    }).toList();
  }

  IconData _iconForAccountType(String accountType) {
    switch (accountType.toLowerCase()) {
      case 'bank':
        return Icons.account_balance;
      case 'upi':
        return Icons.qr_code_2;
      case 'cash':
      default:
        return Icons.payments;
    }
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
}
