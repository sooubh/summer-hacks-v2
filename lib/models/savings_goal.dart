import 'package:student_fin_os/core/utils/firestore_codec.dart';
import 'package:student_fin_os/models/finance_enums.dart';

class SavingsGoal {
  const SavingsGoal({
    required this.id,
    required this.userId,
    required this.title,
    required this.targetAmount,
    required this.savedAmount,
    required this.deadline,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.priority = 1,
  });

  final String id;
  final String userId;
  final String title;
  final double targetAmount;
  final double savedAmount;
  final DateTime deadline;
  final GoalStatus status;
  final int priority;
  final DateTime createdAt;
  final DateTime updatedAt;

  double get progress {
    if (targetAmount <= 0) {
      return 0;
    }
    return (savedAmount / targetAmount).clamp(0, 1);
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'userId': userId,
      'title': title,
      'targetAmount': targetAmount,
      'savedAmount': savedAmount,
      'deadline': FirestoreCodec.writeDateTime(deadline),
      'status': FirestoreCodec.writeEnum(status),
      'priority': priority,
      'createdAt': FirestoreCodec.writeDateTime(createdAt),
      'updatedAt': FirestoreCodec.writeDateTime(updatedAt),
    };
  }

  factory SavingsGoal.fromMap(String id, Map<String, dynamic> data) {
    return SavingsGoal(
      id: id,
      userId: data['userId'] as String? ?? '',
      title: data['title'] as String? ?? 'Goal',
      targetAmount: (data['targetAmount'] as num?)?.toDouble() ?? 0,
      savedAmount: (data['savedAmount'] as num?)?.toDouble() ?? 0,
      deadline: FirestoreCodec.readDateTime(data['deadline']),
      status: FirestoreCodec.readEnum(
        GoalStatus.values,
        data['status'] as String?,
        GoalStatus.active,
      ),
      priority: data['priority'] as int? ?? 1,
      createdAt: FirestoreCodec.readDateTime(data['createdAt']),
      updatedAt: FirestoreCodec.readDateTime(data['updatedAt']),
    );
  }
}
