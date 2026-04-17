import 'package:student_fin_os/core/utils/firestore_codec.dart';
import 'package:student_fin_os/models/finance_enums.dart';

class SplitExpense {
  const SplitExpense({
    required this.id,
    required this.groupId,
    required this.createdBy,
    required this.title,
    required this.totalAmount,
    required this.currency,
    required this.paidBy,
    required this.owedBy,
    required this.status,
    required this.expenseAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String groupId;
  final String createdBy;
  final String title;
  final double totalAmount;
  final String currency;
  final String paidBy;
  final Map<String, double> owedBy;
  final SplitStatus status;
  final DateTime expenseAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'groupId': groupId,
      'createdBy': createdBy,
      'title': title,
      'totalAmount': totalAmount,
      'currency': currency,
      'paidBy': paidBy,
      'owedBy': owedBy,
      'status': FirestoreCodec.writeEnum(status),
      'expenseAt': FirestoreCodec.writeDateTime(expenseAt),
      'createdAt': FirestoreCodec.writeDateTime(createdAt),
      'updatedAt': FirestoreCodec.writeDateTime(updatedAt),
    };
  }

  factory SplitExpense.fromMap(String id, Map<String, dynamic> data) {
    final dynamic rawOwedBy = data['owedBy'];
    final Map<String, dynamic> owedByMap = rawOwedBy is Map<String, dynamic>
        ? rawOwedBy
        : <String, dynamic>{};

    return SplitExpense(
      id: id,
      groupId: data['groupId'] as String? ?? '',
      createdBy: data['createdBy'] as String? ?? '',
      title: data['title'] as String? ?? 'Expense',
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0,
      currency: data['currency'] as String? ?? 'INR',
      paidBy: data['paidBy'] as String? ?? '',
      owedBy: owedByMap.map(
        (String key, dynamic value) =>
            MapEntry<String, double>(key, (value as num?)?.toDouble() ?? 0),
      ),
      status: FirestoreCodec.readEnum(
        SplitStatus.values,
        data['status'] as String?,
        SplitStatus.pending,
      ),
      expenseAt: FirestoreCodec.readDateTime(data['expenseAt']),
      createdAt: FirestoreCodec.readDateTime(data['createdAt']),
      updatedAt: FirestoreCodec.readDateTime(data['updatedAt']),
    );
  }
}
