import 'package:student_fin_os/core/utils/firestore_codec.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.createdAt,
    required this.updatedAt,
    this.photoUrl,
    this.collegeName,
    this.defaultCurrency = 'INR',
  });

  final String id;
  final String fullName;
  final String email;
  final String? photoUrl;
  final String? collegeName;
  final String defaultCurrency;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppUser copyWith({
    String? fullName,
    String? email,
    String? photoUrl,
    String? collegeName,
    String? defaultCurrency,
    DateTime? updatedAt,
  }) {
    return AppUser(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      collegeName: collegeName ?? this.collegeName,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'fullName': fullName,
      'email': email,
      'photoUrl': photoUrl,
      'collegeName': collegeName,
      'defaultCurrency': defaultCurrency,
      'createdAt': FirestoreCodec.writeDateTime(createdAt),
      'updatedAt': FirestoreCodec.writeDateTime(updatedAt),
    };
  }

  factory AppUser.fromMap(String id, Map<String, dynamic> data) {
    return AppUser(
      id: id,
      fullName: data['fullName'] as String? ?? 'Student',
      email: data['email'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      collegeName: data['collegeName'] as String?,
      defaultCurrency: data['defaultCurrency'] as String? ?? 'INR',
      createdAt: FirestoreCodec.readDateTime(data['createdAt']),
      updatedAt: FirestoreCodec.readDateTime(data['updatedAt']),
    );
  }
}
