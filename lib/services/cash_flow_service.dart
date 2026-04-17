import 'package:student_fin_os/models/cash_flow_point.dart';
import 'package:student_fin_os/models/finance_enums.dart';
import 'package:student_fin_os/models/finance_transaction.dart';

class CashFlowService {
  List<CashFlowPoint> project({
    required double openingBalance,
    required List<FinanceTransaction> recentTransactions,
    int days = 14,
  }) {
    final DateTime now = DateTime.now().toUtc();
    final DateTime threshold = now.subtract(const Duration(days: 30));

    final List<FinanceTransaction> baseline = recentTransactions
        .where((FinanceTransaction tx) => tx.transactionAt.isAfter(threshold))
        .toList();

    double totalIncome = 0;
    double totalExpense = 0;

    for (final FinanceTransaction tx in baseline) {
      if (tx.type == TransactionType.income) {
        totalIncome += tx.amount;
      } else if (tx.type == TransactionType.expense ||
          tx.type == TransactionType.splitSettlement) {
        totalExpense += tx.amount;
      }
    }

    final double avgDailyIncome = totalIncome / 30;
    final double avgDailyExpense = totalExpense / 30;

    final List<CashFlowPoint> points = <CashFlowPoint>[];
    double runningBalance = openingBalance;

    for (int offset = 0; offset < days; offset++) {
      runningBalance += avgDailyIncome - avgDailyExpense;

      points.add(CashFlowPoint(
        date: DateTime.utc(now.year, now.month, now.day + offset),
        expectedIncome: avgDailyIncome,
        expectedExpense: avgDailyExpense,
        projectedBalance: runningBalance,
      ));
    }

    return points;
  }

  DateTime? predictedLowBalanceDate(
    List<CashFlowPoint> points, {
    double threshold = 500,
  }) {
    for (final CashFlowPoint point in points) {
      if (point.projectedBalance <= threshold) {
        return point.date;
      }
    }
    return null;
  }
}
