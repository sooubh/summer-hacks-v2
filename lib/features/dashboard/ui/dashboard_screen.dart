import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:student_fin_os/core/utils/currency_formatter.dart';
import 'package:student_fin_os/core/widgets/empty_state.dart';
import 'package:student_fin_os/core/widgets/metric_card.dart';
import 'package:student_fin_os/core/widgets/section_header.dart';
import 'package:student_fin_os/l10n/app_localizations.dart';
import 'package:student_fin_os/models/account.dart';
import 'package:student_fin_os/models/finance_transaction.dart';
import 'package:student_fin_os/providers/dashboard_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final snapshot = ref.watch(dashboardSnapshotProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final List<FinanceTransaction> txList = snapshot.unifiedTransactions;
    final UnifiedPlatformSummary summary = ref.watch(unifiedPlatformSummaryProvider);
    final List<Account> accountList = accountsAsync.value ?? const <Account>[];
    final Map<String, Account> accountById = <String, Account>{
      for (final Account account in accountList) account.id: account,
    };
    final List<String> sourceLabels = accountList
        .map((Account account) => account.provider ?? account.accountType.toUpperCase())
        .toSet()
        .toList();

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
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          l10n.dashboardUnifiedPlatform,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      IconButton.outlined(
                        onPressed: () => context.go('/app/profile'),
                        tooltip: l10n.profile,
                        icon: const Icon(Icons.person_outline),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.dashboardOneCleanView,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  l10n.dashboardConnectedToFeed,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            l10n.dashboardAccountsTransactions(
                              summary.totalAccounts,
                              summary.totalTransactions,
                            ),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.dashboardLiveUpdates,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: sourceLabels.isEmpty
                                ? <Widget>[
                                    _sourceChip(context, label: l10n.dashboardNoSourcesYet),
                                  ]
                                : sourceLabels
                                    .map((String source) => _sourceChip(context, label: source))
                                    .toList(),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: _platformTile(
                                  context,
                                  icon: Icons.account_balance,
                                  title: l10n.bank,
                                  value: CurrencyFormatter.inr(summary.bankBalance),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _platformTile(
                                  context,
                                  icon: Icons.qr_code_2,
                                  title: l10n.upi,
                                  value: CurrencyFormatter.inr(summary.upiBalance),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _platformTile(
                                  context,
                                  icon: Icons.payments,
                                  title: l10n.cash,
                                  value: CurrencyFormatter.inr(summary.cashBalance),
                                ),
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
                        label: l10n.totalBalance,
                        value: CurrencyFormatter.inr(snapshot.totalBalance),
                        gradient: const <Color>[Color(0xFF8ABF9E), Color(0xFF68A57F)],
                      ),
                      MetricCard(
                        label: l10n.safeToSpend,
                        value: CurrencyFormatter.inr(snapshot.safeToSpend),
                        gradient: const <Color>[Color(0xFF8CB6D9), Color(0xFF6A9BC8)],
                      ),
                      MetricCard(
                        label: l10n.weeklySpend,
                        value: CurrencyFormatter.inr(snapshot.weeklySpend),
                        gradient: const <Color>[Color(0xFFC6B4DF), Color(0xFFAA93CE)],
                      ),
                      MetricCard(
                        label: l10n.burnRatePerDay,
                        value: CurrencyFormatter.inr(snapshot.burnRate),
                        gradient: const <Color>[Color(0xFFE8C59A), Color(0xFFD9AD74)],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SectionHeader(
                    title: l10n.smartGuidance,
                    subtitle: l10n.smartGuidanceSubtitle,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      _GuidanceTipItem(
                        icon: Icons.shield_outlined,
                        label: l10n.tipAtmSafety,
                        tip: l10n.tipAtmSafetyBody,
                      ),
                      _GuidanceTipItem(
                        icon: Icons.credit_card,
                        label: l10n.tipCreditScore,
                        tip: l10n.tipCreditScoreBody,
                      ),
                      _GuidanceTipItem(
                        icon: Icons.savings_outlined,
                        label: l10n.tipBudgeting,
                        tip: l10n.tipBudgetingBody,
                      ),
                      _GuidanceTipItem(
                        icon: Icons.trending_up,
                        label: l10n.tipInvesting,
                        tip: l10n.tipInvestingBody,
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
                    height: 110,
                    child: _topSpendingsRow(context, snapshot.categoryBreakdown),
                  ),
                  const SizedBox(height: 18),
                  SectionHeader(
                    title: l10n.connectedAccounts,
                    subtitle: l10n.connectedAccountsSubtitle,
                  ),
                  const SizedBox(height: 10),
                  accountsAsync.when(
                    data: (List<Account> accounts) {
                      if (accounts.isEmpty) {
                        return EmptyState(
                          title: l10n.noAccountsYet,
                          message: l10n.noAccountsYetBody,
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
                              subtitle: Text(
                                '${item.provider ?? l10n.wallet} • ${item.accountType.toUpperCase()}',
                              ),
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
                    error: (Object error, StackTrace stackTrace) => Text('${l10n.errorPrefix}: $error'),
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
                        : PieChart(
                            PieChartData(
                              centerSpaceRadius: 50,
                              sectionsSpace: 2,
                              sections: _buildCategorySections(snapshot.categoryBreakdown),
                            ),
                          ),
                  ),
                  const SizedBox(height: 18),
                  SectionHeader(
                    title: l10n.recentActivity,
                    subtitle: l10n.latestTransactions,
                  ),
                  const SizedBox(height: 8),
                  if (txList.isEmpty)
                    EmptyState(
                      title: l10n.noTransactionsFound,
                      message: l10n.noTransactionsFoundBody,
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
                          subtitle: Text(
                            '${tx.category} • ${_platformLabelForTransaction(tx, accountById)}',
                          ),
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

  Widget _platformTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 17),
          const SizedBox(height: 6),
          Text(title, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _sourceChip(BuildContext context, {required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _topSpendingsRow(BuildContext context, Map<String, double> categoryBreakdown) {
    final List<MapEntry<String, double>> items = categoryBreakdown.entries.toList()
      ..sort((MapEntry<String, double> a, MapEntry<String, double> b) => b.value.compareTo(a.value));

    final List<MapEntry<String, double>> top = items.take(3).toList();
    if (top.isEmpty) {
      return const EmptyState(
        title: 'No top spendings yet',
        message: 'Add expenses to see your top categories.',
        icon: Icons.local_offer_outlined,
      );
    }

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: top.length,
      separatorBuilder: (BuildContext context, int index) => const SizedBox(width: 10),
      itemBuilder: (BuildContext context, int index) {
        final MapEntry<String, double> entry = top[index];
        return Container(
          width: 120,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              CircleAvatar(
                radius: 16,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Icon(_categoryIcon(entry.key), size: 18),
              ),
              const SizedBox(height: 8),
              Text(
                entry.key[0].toUpperCase() + entry.key.substring(1),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _categoryIcon(String category) {
    final String normalized = category.toLowerCase();
    if (normalized.contains('food')) {
      return Icons.restaurant;
    }
    if (normalized.contains('shop')) {
      return Icons.shopping_bag_outlined;
    }
    if (normalized.contains('travel')) {
      return Icons.directions_car_outlined;
    }
    return Icons.local_offer_outlined;
  }

  String _platformLabelForTransaction(
    FinanceTransaction tx,
    Map<String, Account> accountById,
  ) {
    final Account? account = accountById[tx.accountId];
    if (account == null) {
      return tx.channel.toUpperCase();
    }
    return '${account.provider ?? account.accountType.toUpperCase()} ${account.accountType.toUpperCase()}';
  }
}

class _GuidanceTipItem extends StatelessWidget {
  const _GuidanceTipItem({
    required this.icon,
    required this.label,
    required this.tip,
  });

  final IconData icon;
  final String label;
  final String tip;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tip)),
        );
      },
      child: SizedBox(
        width: 78,
        child: Column(
          children: <Widget>[
            CircleAvatar(
              radius: 20,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Icon(icon),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
