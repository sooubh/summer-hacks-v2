class DashboardSnapshot {
  const DashboardSnapshot({
    required this.totalBalance,
    required this.weeklySpend,
    required this.monthlySpend,
    required this.burnRate,
    required this.safeToSpend,
    required this.categoryBreakdown,
  });

  final double totalBalance;
  final double weeklySpend;
  final double monthlySpend;
  final double burnRate;
  final double safeToSpend;
  final Map<String, double> categoryBreakdown;

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
}
