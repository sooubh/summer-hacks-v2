import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:student_fin_os/core/utils/currency_formatter.dart';
import 'package:student_fin_os/core/widgets/section_header.dart';
import 'package:student_fin_os/models/cash_flow_point.dart';
import 'package:student_fin_os/providers/cash_flow_providers.dart';

class CashFlowScreen extends ConsumerWidget {
  const CashFlowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<CashFlowPoint> points = ref.watch(cashFlowProjectionProvider);
    final DateTime? lowDate = ref.watch(predictedLowBalanceDateProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SectionHeader(
              title: 'Cash flow timeline',
              subtitle: 'Income vs expenses projection (14 days)',
            ),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: const Icon(Icons.notification_important),
                title: const Text('Low balance alert window'),
                subtitle: Text(
                  lowDate == null
                      ? 'No low-balance day expected this cycle.'
                      : 'Potential dip around ${DateFormat('dd MMM').format(lowDate)}. Reduce non-essential spend.',
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 250,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: (points.length - 1).toDouble(),
                      lineBarsData: <LineChartBarData>[
                        LineChartBarData(
                          spots: _balanceSpots(points),
                          isCurved: true,
                          barWidth: 3,
                          color: const Color(0xFF2AE4C9),
                        ),
                      ],
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: true, reservedSize: 44),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              final int index = value.toInt();
                              if (index < 0 || index >= points.length || index % 3 != 0) {
                                return const SizedBox.shrink();
                              }
                              final String day = DateFormat('dd').format(points[index].date);
                              return Text(day, style: const TextStyle(fontSize: 10));
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: points.length,
                itemBuilder: (BuildContext context, int index) {
                  final CashFlowPoint item = points[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: Text(DateFormat('EEE, dd MMM').format(item.date)),
                      subtitle: Text(
                        'Income ${CurrencyFormatter.inr(item.expectedIncome)} • Expense ${CurrencyFormatter.inr(item.expectedExpense)}',
                      ),
                      trailing: Text(CurrencyFormatter.inr(item.projectedBalance)),
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

  List<FlSpot> _balanceSpots(List<CashFlowPoint> points) {
    return points.asMap().entries.map((MapEntry<int, CashFlowPoint> entry) {
      return FlSpot(entry.key.toDouble(), entry.value.projectedBalance);
    }).toList();
  }
}
