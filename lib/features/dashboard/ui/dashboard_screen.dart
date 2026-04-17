import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_fin_os/core/utils/currency_formatter.dart';
import 'package:student_fin_os/core/widgets/empty_state.dart';
import 'package:student_fin_os/core/widgets/metric_card.dart';
import 'package:student_fin_os/core/widgets/section_header.dart';
import 'package:student_fin_os/l10n/app_localizations.dart';
import 'package:student_fin_os/models/finance_transaction.dart';
import 'package:student_fin_os/models/finance_enums.dart';
import 'package:student_fin_os/providers/dashboard_providers.dart';
import 'package:student_fin_os/features/dashboard/ui/transaction_details_sheet.dart';
import 'package:student_fin_os/providers/auth_providers.dart';
import 'package:student_fin_os/providers/firebase_providers.dart';
import 'package:student_fin_os/core/utils/brand_styles.dart';
import 'package:student_fin_os/core/utils/dummy_data.dart';
import 'package:student_fin_os/features/dashboard/ui/spending_modules_screen.dart';
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

  Future<void> _injectDummyTransactions() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    final txService = ref.read(transactionServiceProvider);
    final accountService = ref.read(accountServiceProvider);
    
    final accounts = await accountService.watchAccounts(userId).first;
    if (accounts.isEmpty) return;

    setState(() => _isSeeding = true);

    final String accountId = accounts.first.id;
    final now = DateTime.now();
    final uid = const Uuid();

    final List<Map<String, dynamic>> dummies = generateDummyTransactions();

    for (int i = 0; i < dummies.length; i++) {
      final d = dummies[i];
      final isExp = d['isIncome'] != true;
      final tx = FinanceTransaction(
        id: uid.v4(),
        userId: userId,
        accountId: accountId,
        title: d['title'],
        amount: d['amount'],
        type: isExp ? TransactionType.expense : TransactionType.income,
        category: d['cat'],
        transactionAt: now.subtract(Duration(days: i)),
        createdAt: now,
        updatedAt: now,
        source: d['src'],
        channel: 'upi',
      );
      await txService.createTransaction(tx);
    }

    setState(() => _isSeeding = false);
  }



  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final snapshot = ref.watch(dashboardSnapshotProvider);
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
                        Row(
                          children: [
                            Text(
                              _isBalanceVisible ? CurrencyFormatter.inr(snapshot.totalBalance) : '••••••',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
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
                        label: 'Total Saved',
                        value: CurrencyFormatter.inr(snapshot.totalSavings),
                        gradient: const <Color>[Color(0xFF8ABF9E), Color(0xFF68A57F)],
                        suggestionIcon: Icons.trending_up,
                        suggestionText: 'Good progress',
                        suggestionColor: Colors.green,
                      ),
                      MetricCard(
                        label: l10n.safeToSpend,
                        value: CurrencyFormatter.inr(snapshot.safeToSpend),
                        gradient: const <Color>[Color(0xFF8CB6D9), Color(0xFF6A9BC8)],
                        suggestionIcon: Icons.check_circle_outline,
                        suggestionText: 'Stress-free limit',
                        suggestionColor: Colors.blue,
                      ),
                      MetricCard(
                        label: l10n.weeklySpend,
                        value: CurrencyFormatter.inr(snapshot.weeklySpend),
                        gradient: const <Color>[Color(0xFFC6B4DF), Color(0xFFAA93CE)],
                        suggestionIcon: Icons.insights,
                        suggestionText: 'Track it closely',
                        suggestionColor: Colors.purple,
                      ),
                      MetricCard(
                        label: l10n.burnRatePerDay,
                        value: CurrencyFormatter.inr(snapshot.burnRate),
                        gradient: const <Color>[Color(0xFFE8C59A), Color(0xFFD9AD74)],
                        suggestionIcon: Icons.warning_amber_rounded,
                        suggestionText: 'Keep it low',
                        suggestionColor: Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const SectionHeader(
                    title: 'AI Insights & Strategy',
                    subtitle: 'Smart options to grow your wealth instead of spending randomly.',
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 140,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: <Widget>[
                        _AiStrategyCard(
                          icon: Icons.pie_chart_outline,
                          title: 'Budget Options',
                          description: 'Use the 50/30/20 rule to stop random spending.',
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
                          title: 'Saving Options',
                          description: 'Automate 10% of income directly to an emergency fund.',
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
                          title: 'Investing',
                          description: 'Start SIPs in Index Funds to beat inflation.',
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
                                const SizedBox(height: 4),
                                Text(
                                  'Learn platform hacks & save money on Amazon, Zomato, Uber & 20+ more.',
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
                          'Actively using these hacks will lower your weekly burn rate and dynamically update AI predictions across insights & savings.',
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
                    height: 110,
                    child: _topSpendingsRow(context, snapshot.categoryBreakdown),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: SectionHeader(
                          title: l10n.recentActivity,
                          subtitle: l10n.latestTransactions,
                        ),
                      ),
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
        width: 220,
        padding: const EdgeInsets.all(16),
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
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: <Widget>[
                Text(
                  'Explore AI Ideas',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(   
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward, size: 14, color: color),
              ],
            ),
          ],
        ),

      ),
    );
  }
}
