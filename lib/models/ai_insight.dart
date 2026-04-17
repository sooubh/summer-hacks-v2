import 'package:student_fin_os/core/utils/firestore_codec.dart';
import 'package:student_fin_os/models/finance_enums.dart';

class AiInsight {
  const AiInsight({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.severity,
    required this.createdAt,
    required this.isRead,
    this.meta = const <String, dynamic>{},
  });

  final String id;
  final String userId;
  final String title;
  final String message;
  final InsightSeverity severity;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic> meta;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'userId': userId,
      'title': title,
      'message': message,
      'severity': FirestoreCodec.writeEnum(severity),
      'createdAt': FirestoreCodec.writeDateTime(createdAt),
      'isRead': isRead,
      'meta': meta,
    };
  }

  factory AiInsight.fromMap(String id, Map<String, dynamic> data) {
    return AiInsight(
      id: id,
      userId: data['userId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      message: data['message'] as String? ?? '',
      severity: FirestoreCodec.readEnum(
        InsightSeverity.values,
        data['severity'] as String?,
        InsightSeverity.info,
      ),
      createdAt: FirestoreCodec.readDateTime(data['createdAt']),
      isRead: data['isRead'] as bool? ?? false,
      meta: (data['meta'] as Map<String, dynamic>?) ?? <String, dynamic>{},
    );
  }
}
