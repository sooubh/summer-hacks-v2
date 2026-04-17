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
  Widget build(BuildContext context, WidgetRef ref) {
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

    return SafeArea(
      child: Padding(
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
