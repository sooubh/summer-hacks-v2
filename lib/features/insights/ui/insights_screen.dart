import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:student_fin_os/core/widgets/empty_state.dart';
import 'package:student_fin_os/core/widgets/section_header.dart';
import 'package:student_fin_os/models/ai_insight.dart';
import 'package:student_fin_os/models/finance_enums.dart';
import 'package:student_fin_os/providers/cash_flow_providers.dart';
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
    final DateTime? lowBalanceDate = ref.watch(predictedLowBalanceDateProvider);

    final List<AiInsight> filtered = insights.where((AiInsight insight) {
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

    final int criticalCount = insights
        .where((AiInsight insight) => insight.severity == InsightSeverity.critical)
        .length;
    final int warningCount = insights
        .where((AiInsight insight) => insight.severity == InsightSeverity.warning)
        .length;
    final int infoCount = insights
        .where((AiInsight insight) => insight.severity == InsightSeverity.info)
        .length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                colors: <Color>[
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.24),
                  Theme.of(context).colorScheme.secondary.withValues(alpha: 0.18),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Unified Insights',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'Simple money tips you can act on right now.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
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
                label: const Text('Refresh'),
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
          Expanded(
            child: filtered.isEmpty
                ? const EmptyState(
                    title: 'No insights in this filter',
                    message: 'Tap Refresh or switch filter to see your money tips.',
                    icon: Icons.lightbulb,
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (BuildContext context, int index) {
                      final AiInsight insight = filtered[index];
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
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionHeader(
          title: 'Budgeting Methods',
          subtitle: 'Proven frameworks to organize your money.',
        ),
        const SizedBox(height: 16),
        _infoCard(
          context,
          icon: Icons.pie_chart,
          title: 'The 50/30/20 Rule',
          description: 'Allocate 50% to Needs (rent, groceries), 30% to Wants (hobbies, dining out), and 20% to Savings or Debt.',
        ),
        _infoCard(
          context,
          icon: Icons.account_balance_wallet,
          title: 'Zero-Based Budgeting',
          description: 'Give every single rupee a job until your income minus expenses equals exactly zero.',
        ),
        _infoCard(
          context,
          icon: Icons.mail_outline,
          title: 'Envelope System',
          description: 'Allocate specific amounts to categories. Once the "envelope" is empty, you stop spending in that category.',
        ),
      ],
    );
  }

  Widget _buildSavingsTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionHeader(
          title: 'Smart Saving Hacks',
          subtitle: 'Stop spending on random things and grow your wealth.',
        ),
        const SizedBox(height: 16),
        _infoCard(
          context,
          icon: Icons.savings,
          title: 'Pay Yourself First',
          description: 'The moment your paycheck arrives, move a fixed percentage into savings before doing anything else.',
        ),
        _infoCard(
          context,
          icon: Icons.coffee,
          title: 'The 24-Hour Rule',
          description: 'Before making an impulse purchase, wait 24 hours. The urge usually disappears.',
        ),
        _infoCard(
          context,
          icon: Icons.autorenew,
          title: 'Automate Savings',
          description: 'Set up recurring transfers to an emergency fund. What you don''t see, you won''t spend.',
        ),
        _infoCard(
          context,
          icon: Icons.price_change,
          title: 'Cut Unused Subscriptions',
          description: 'Review your monthly recurring automated payments. Cancel the ones you haven''t used in 30 days.',
        ),
      ],
    );
  }

  Widget _buildInvestingTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionHeader(
          title: 'Investing Basics',
          subtitle: 'Make your money work for you, securely.',
        ),
        const SizedBox(height: 16),
        _infoCard(
          context,
          icon: Icons.trending_up,
          title: 'Index Funds & ETFs',
          description: 'Rather than picking single stocks, buy a basket of top companies. Low fees, steady long-term growth.',
        ),
        _infoCard(
          context,
          icon: Icons.show_chart,
          title: 'Mutual Funds / SIPs',
          description: 'Start a Systematic Investment Plan. Invest a small amount every month to average out market volatility.',
        ),
        _infoCard(
          context,
          icon: Icons.security,
          title: 'Emergency Fund Core',
          description: 'Before taking stock market risks, ensure you have 3-6 months of living expenses in a liquid savings account/FD.',
        ),
        _infoCard(
          context,
          icon: Icons.account_balance,
          title: 'Fixed Deposits (FD/RD)',
          description: 'Low-risk instrument for short-term goals. Guaranteed returns over a set period.',
        ),
      ],
    );
  }

  Widget _infoCard(BuildContext context, {required IconData icon, required String title, required String description}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(icon, color: Theme.of(context).colorScheme.onPrimaryContainer),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
