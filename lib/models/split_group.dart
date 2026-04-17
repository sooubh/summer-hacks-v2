import 'package:student_fin_os/core/utils/firestore_codec.dart';

class SplitGroup {
  const SplitGroup({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.memberIds,
    required this.createdAt,
    required this.updatedAt,
    this.description,
  });

  final String id;
  final String ownerId;
  final String name;
  final List<String> memberIds;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'ownerId': ownerId,
      'name': name,
      'memberIds': memberIds,
      'description': description,
      'createdAt': FirestoreCodec.writeDateTime(createdAt),
      'updatedAt': FirestoreCodec.writeDateTime(updatedAt),
    };
  }

  factory SplitGroup.fromMap(String id, Map<String, dynamic> data) {
    return SplitGroup(
      id: id,
      ownerId: data['ownerId'] as String? ?? '',
      name: data['name'] as String? ?? 'Group',
      memberIds: (data['memberIds'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic item) => item.toString())
          .toList(),
      description: data['description'] as String?,
      createdAt: FirestoreCodec.readDateTime(data['createdAt']),
      updatedAt: FirestoreCodec.readDateTime(data['updatedAt']),
    );
  }
}
