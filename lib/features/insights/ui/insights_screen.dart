import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:student_fin_os/core/widgets/empty_state.dart';
import 'package:student_fin_os/core/widgets/section_header.dart';
import 'package:student_fin_os/models/ai_insight.dart';
import 'package:student_fin_os/models/finance_enums.dart';
import 'package:student_fin_os/providers/cash_flow_providers.dart';
import 'package:student_fin_os/providers/insights_providers.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<AiInsight> insights = ref.watch(insightsFeedProvider).value ?? const <AiInsight>[];
    final DateTime? lowBalanceDate = ref.watch(predictedLowBalanceDateProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Expanded(
                  child: SectionHeader(
                    title: 'AI insights',
                    subtitle: 'Rule-based coaching and alerts',
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
                title: const Text('Low-balance prediction'),
                subtitle: Text(
                  lowBalanceDate == null
                      ? 'No low-balance day predicted in next 14 days.'
                      : 'Projected balance may drop critically around ${DateFormat('dd MMM').format(lowBalanceDate)}.',
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: insights.isEmpty
                  ? const EmptyState(
                      title: 'No insights yet',
                      message: 'Tap Refresh to generate your first set of smart spending insights.',
                      icon: Icons.lightbulb,
                    )
                  : ListView.builder(
                      itemCount: insights.length,
                      itemBuilder: (BuildContext context, int index) {
                        final AiInsight insight = insights[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Icon(
                              _iconForSeverity(insight.severity),
                              color: _colorForSeverity(insight.severity),
                            ),
                            title: Text(insight.title),
                            subtitle: Text(insight.message),
                            trailing: Text(DateFormat('dd MMM').format(insight.createdAt)),
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
