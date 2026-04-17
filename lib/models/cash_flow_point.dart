import 'package:student_fin_os/core/utils/firestore_codec.dart';

class CashFlowPoint {
  const CashFlowPoint({
    required this.date,
    required this.expectedIncome,
    required this.expectedExpense,
    required this.projectedBalance,
  });

  final DateTime date;
  final double expectedIncome;
  final double expectedExpense;
  final double projectedBalance;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'date': FirestoreCodec.writeDateTime(date),
      'expectedIncome': expectedIncome,
      'expectedExpense': expectedExpense,
      'projectedBalance': projectedBalance,
    };
  }

  factory CashFlowPoint.fromMap(Map<String, dynamic> data) {
    return CashFlowPoint(
      date: FirestoreCodec.readDateTime(data['date']),
      expectedIncome: (data['expectedIncome'] as num?)?.toDouble() ?? 0,
      expectedExpense: (data['expectedExpense'] as num?)?.toDouble() ?? 0,
      projectedBalance: (data['projectedBalance'] as num?)?.toDouble() ?? 0,
    );
  }
}
