import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_fin_os/core/utils/currency_formatter.dart';
import 'package:student_fin_os/core/widgets/empty_state.dart';
import 'package:student_fin_os/core/widgets/metric_card.dart';
import 'package:student_fin_os/core/widgets/section_header.dart';
import 'package:student_fin_os/models/finance_transaction.dart';
import 'package:student_fin_os/providers/dashboard_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(dashboardSnapshotProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final txList = ref.watch(transactionsProvider).value ?? const <FinanceTransaction>[];

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
                    'Money cockpit',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your total spending pulse for this week.',
                    style: Theme.of(context).textTheme.bodySmall,
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
                        gradient: const <Color>[Color(0xFF123C58), Color(0xFF1C7C89)],
                      ),
                      MetricCard(
                        label: 'Safe to spend',
                        value: CurrencyFormatter.inr(snapshot.safeToSpend),
                        gradient: const <Color>[Color(0xFF15415A), Color(0xFF2ABF9E)],
                      ),
                      MetricCard(
                        label: 'Weekly spend',
                        value: CurrencyFormatter.inr(snapshot.weeklySpend),
                        gradient: const <Color>[Color(0xFF46213E), Color(0xFFBD4F6C)],
                      ),
                      MetricCard(
                        label: 'Burn rate/day',
                        value: CurrencyFormatter.inr(snapshot.burnRate),
                        gradient: const <Color>[Color(0xFF3F2B16), Color(0xFFBF6E2B)],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const SectionHeader(
                    title: 'Connected balances',
                    subtitle: 'Bank + UPI + cash unified',
                  ),
                  const SizedBox(height: 10),
                  accountsAsync.when(
                    data: (List<dynamic> accounts) {
                      if (accounts.isEmpty) {
                        return const EmptyState(
                          title: 'No accounts yet',
                          message:
                              'Create your first account or seed mock bank data to view the dashboard.',
                          icon: Icons.account_balance_wallet,
                        );
                      }
                      return Column(
                        children: accounts.map((dynamic account) {
                          final item = account;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const Icon(Icons.account_balance_wallet),
                              title: Text(item.name as String),
                              subtitle: Text(item.provider?.toString() ?? 'wallet'),
                              trailing: Text(
                                CurrencyFormatter.inr(item.balance as num),
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
                    error: (Object error, StackTrace stackTrace) {
                      return Text('Error: $error');
                    },
                  ),
                  const SizedBox(height: 18),
                  const SectionHeader(
                    title: 'Category split (30d)',
                    subtitle: 'Where your money went',
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 220,
                    child: snapshot.categoryBreakdown.isEmpty
                        ? const EmptyState(
                            title: 'No category data yet',
                            message: 'Add a few transactions to unlock spending insights.',
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
                    title: 'Recent transactions',
                    subtitle: 'Latest 6 entries',
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
}
