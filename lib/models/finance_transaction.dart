import 'package:student_fin_os/core/utils/firestore_codec.dart';
import 'package:student_fin_os/models/finance_enums.dart';

class FinanceTransaction {
  const FinanceTransaction({
    required this.id,
    required this.userId,
    required this.accountId,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.transactionAt,
    required this.createdAt,
    required this.updatedAt,
    this.tags = const <String>[],
    this.note,
    this.source = 'manual',
  });

  final String id;
  final String userId;
  final String accountId;
  final String title;
  final double amount;
  final TransactionType type;
  final String category;
  final DateTime transactionAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> tags;
  final String? note;
  final String source;

  bool get isExpense => type == TransactionType.expense;
  bool get isIncome => type == TransactionType.income;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'userId': userId,
      'accountId': accountId,
      'title': title,
      'amount': amount,
      'type': FirestoreCodec.writeEnum(type),
      'category': category,
      'transactionAt': FirestoreCodec.writeDateTime(transactionAt),
      'createdAt': FirestoreCodec.writeDateTime(createdAt),
      'updatedAt': FirestoreCodec.writeDateTime(updatedAt),
      'tags': tags,
      'note': note,
      'source': source,
    };
  }

  factory FinanceTransaction.fromMap(String id, Map<String, dynamic> data) {
    return FinanceTransaction(
      id: id,
      userId: data['userId'] as String? ?? '',
      accountId: data['accountId'] as String? ?? '',
      title: data['title'] as String? ?? 'Untitled',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      type: FirestoreCodec.readEnum(
        TransactionType.values,
        data['type'] as String?,
        TransactionType.expense,
      ),
      category: data['category'] as String? ?? 'misc',
      transactionAt: FirestoreCodec.readDateTime(data['transactionAt']),
      createdAt: FirestoreCodec.readDateTime(data['createdAt']),
      updatedAt: FirestoreCodec.readDateTime(data['updatedAt']),
      tags: (data['tags'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic item) => item.toString())
          .toList(),
      note: data['note'] as String?,
      source: data['source'] as String? ?? 'manual',
    );
  }
}
