import 'package:student_fin_os/models/finance_transaction.dart';

class DashboardSnapshot {
  const DashboardSnapshot({
    required this.totalBalance,
    required this.weeklySpend,
    required this.monthlySpend,
    required this.burnRate,
    required this.safeToSpend,
    required this.categoryBreakdown,
    required this.monthlySpendByKey,
    required this.currentMonthSpend,
    required this.previousMonthSpend,
    required this.unifiedTransactions,
  });

  final double totalBalance;
  final double weeklySpend;
  final double monthlySpend;
  final double burnRate;
  final double safeToSpend;
  final Map<String, double> categoryBreakdown;
  final Map<String, double> monthlySpendByKey;
  final double currentMonthSpend;
  final double previousMonthSpend;
  final List<FinanceTransaction> unifiedTransactions;

  double get monthlyTrendPercent {
    if (previousMonthSpend <= 0) {
      return currentMonthSpend > 0 ? 100 : 0;
    }
    return ((currentMonthSpend - previousMonthSpend) / previousMonthSpend) * 100;
  }

  bool get isMonthlySpendUp => monthlyTrendPercent > 0;

  String get topCategory {
    if (categoryBreakdown.isEmpty) {
      return 'none';
    }

    String winner = categoryBreakdown.keys.first;
    double max = categoryBreakdown[winner] ?? 0;

    categoryBreakdown.forEach((String key, double value) {
      if (value > max) {
        winner = key;
        max = value;
      }
    });

    return winner;
  }

  List<MapEntry<String, double>> get monthlySpendEntries {
    final List<MapEntry<String, double>> entries = monthlySpendByKey.entries.toList()
      ..sort((MapEntry<String, double> a, MapEntry<String, double> b) {
        return a.key.compareTo(b.key);
      });
    return entries;
  }
}
