import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:student_fin_os/models/ai_insight.dart';
import 'package:student_fin_os/models/finance_enums.dart';
import 'package:student_fin_os/models/finance_transaction.dart';
import 'package:uuid/uuid.dart';

class InsightsService {
  InsightsService(this._firestore, this._uuid);

  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  CollectionReference<Map<String, dynamic>> _insights(String userId) {
    return _firestore.collection('users').doc(userId).collection('insights');
  }

  Stream<List<AiInsight>> watchInsights(String userId) {
    return _insights(userId)
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
      return snapshot.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
            return AiInsight.fromMap(doc.id, doc.data());
          })
          .toList();
    });
  }

  Future<void> persistInsights(String userId, List<AiInsight> items) async {
    if (items.isEmpty) {
      return;
    }

    final WriteBatch batch = _firestore.batch();
    for (final AiInsight insight in items) {
      final DocumentReference<Map<String, dynamic>> ref =
          _insights(userId).doc(insight.id);
      batch.set(ref, insight.toMap(), SetOptions(merge: true));
    }
    await batch.commit();
  }

  List<AiInsight> generateRuleBasedInsights({
    required String userId,
    required List<FinanceTransaction> recentTransactions,
    required double totalBalance,
    required double safeToSpend,
  }) {
    final DateTime now = DateTime.now().toUtc();
    final List<FinanceTransaction> expenses = recentTransactions
        .where((FinanceTransaction tx) => tx.type == TransactionType.expense)
        .toList();

    final List<AiInsight> insights = <AiInsight>[];

    final double weeklyExpense = _sumAmount(
      expenses.where((FinanceTransaction tx) {
        return now.difference(tx.transactionAt).inDays <= 7;
      }).toList(),
    );

    final double previousWeekExpense = _sumAmount(
      expenses.where((FinanceTransaction tx) {
        final int days = now.difference(tx.transactionAt).inDays;
        return days > 7 && days <= 14;
      }).toList(),
    );

    if (previousWeekExpense > 0 && weeklyExpense > previousWeekExpense * 1.25) {
      insights.add(_build(
        userId: userId,
        title: 'You are spending faster this week',
        message:
            'Your spend is ${((weeklyExpense / previousWeekExpense) * 100).round()}% of last week. Try a short no-spend streak on non-essentials.',
        severity: InsightSeverity.warning,
      ));
    }

    final double foodExpense = _sumAmount(
      expenses
          .where((FinanceTransaction tx) =>
              tx.category.toLowerCase() == 'food' ||
              tx.category.toLowerCase() == 'eating out')
          .toList(),
    );

    if (weeklyExpense > 0 && foodExpense / weeklyExpense > 0.45) {
      insights.add(_build(
        userId: userId,
        title: 'Food is taking a big share',
        message:
            'Food is ${((foodExpense / weeklyExpense) * 100).round()}% of weekly spend. 1-2 home-cooked days can lower this quickly.',
        severity: InsightSeverity.info,
      ));
    }

    if (safeToSpend < totalBalance * 0.15) {
      insights.add(_build(
        userId: userId,
        title: 'Your safe-to-spend is low',
        message:
            'You are close to your safety buffer. Keep spending to essentials until next income.',
        severity: InsightSeverity.critical,
      ));
    }

    final DateTime monthStart = DateTime.utc(now.year, now.month, 1);
    final DateTime previousMonthStart = DateTime.utc(now.year, now.month - 1, 1);
    final DateTime previousMonthEnd = monthStart.subtract(const Duration(days: 1));

    final double currentMonthFood = _sumAmount(
      expenses.where((FinanceTransaction tx) {
        return (tx.transactionAt.isAfter(monthStart) ||
                tx.transactionAt.isAtSameMomentAs(monthStart)) &&
            tx.category.toLowerCase() == 'food';
      }).toList(),
    );

    final double previousMonthFood = _sumAmount(
      expenses.where((FinanceTransaction tx) {
        final DateTime date = tx.transactionAt;
        return (date.isAfter(previousMonthStart) || date.isAtSameMomentAs(previousMonthStart)) &&
            (date.isBefore(previousMonthEnd) || date.isAtSameMomentAs(previousMonthEnd)) &&
            tx.category.toLowerCase() == 'food';
      }).toList(),
    );

    if (previousMonthFood > 0 && currentMonthFood > previousMonthFood * 1.3) {
      insights.add(_build(
        userId: userId,
        title: 'Food spending jumped this month',
        message:
            'You spent ${((currentMonthFood - previousMonthFood) / previousMonthFood * 100).round()}% more on food vs last month.',
        severity: InsightSeverity.warning,
      ));
    }

    final double recent14DayExpense = _sumAmount(
      expenses.where((FinanceTransaction tx) {
        return now.difference(tx.transactionAt).inDays <= 14;
      }).toList(),
    );
    final double dailyRunRate = recent14DayExpense / 14;
    if (dailyRunRate > 0) {
      final int projectedDays = (totalBalance / dailyRunRate).floor();
      if (projectedDays <= 5) {
        insights.add(_build(
          userId: userId,
          title: 'Your balance may get tight soon',
          message: 'At this pace, funds may run low in about $projectedDays days. Slow spending this week if possible.',
          severity: InsightSeverity.critical,
        ));
      }
    }

    final bool noIncomeInTwoWeeks = recentTransactions.where((FinanceTransaction tx) {
      return tx.type == TransactionType.income &&
          now.difference(tx.transactionAt).inDays <= 14;
    }).isEmpty;

    if (noIncomeInTwoWeeks) {
      insights.add(_build(
        userId: userId,
        title: 'No income seen in 14 days',
        message:
            'No income landed in the last 14 days. Keep your plan conservative until next credit.',
        severity: InsightSeverity.warning,
      ));
    }

    return insights;
  }

  AiInsight _build({
    required String userId,
    required String title,
    required String message,
    required InsightSeverity severity,
  }) {
    return AiInsight(
      id: _uuid.v4(),
      userId: userId,
      title: title,
      message: message,
      severity: severity,
      createdAt: DateTime.now().toUtc(),
      isRead: false,
    );
  }

  double _sumAmount(List<FinanceTransaction> transactions) {
    double total = 0;
    for (final FinanceTransaction tx in transactions) {
      total += tx.amount;
    }
    return total;
  }
}
