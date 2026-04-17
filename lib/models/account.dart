import 'package:student_fin_os/core/utils/firestore_codec.dart';
import 'package:student_fin_os/models/finance_enums.dart';

class Account {
  const Account({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.balance,
    required this.createdAt,
    required this.updatedAt,
    this.provider,
    this.isActive = true,
    this.icon = 'wallet',
  });

  final String id;
  final String userId;
  final String name;
  final AccountType type;
  final String? provider;
  final double balance;
  final bool isActive;
  final String icon;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'userId': userId,
      'name': name,
      'type': FirestoreCodec.writeEnum(type),
      'provider': provider,
      'balance': balance,
      'isActive': isActive,
      'icon': icon,
      'createdAt': FirestoreCodec.writeDateTime(createdAt),
      'updatedAt': FirestoreCodec.writeDateTime(updatedAt),
    };
  }

  factory Account.fromMap(String id, Map<String, dynamic> data) {
    return Account(
      id: id,
      userId: data['userId'] as String? ?? '',
      name: data['name'] as String? ?? 'Account',
      type: FirestoreCodec.readEnum(
        AccountType.values,
        data['type'] as String?,
        AccountType.cash,
      ),
      provider: data['provider'] as String?,
      balance: (data['balance'] as num?)?.toDouble() ?? 0,
      isActive: data['isActive'] as bool? ?? true,
      icon: data['icon'] as String? ?? 'wallet',
      createdAt: FirestoreCodec.readDateTime(data['createdAt']),
      updatedAt: FirestoreCodec.readDateTime(data['updatedAt']),
    );
  }
}
