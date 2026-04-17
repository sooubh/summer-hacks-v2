import 'dart:convert';

import 'package:flutter/services.dart';

class MockSeed {
  const MockSeed({
    required this.accounts,
    required this.transactions,
    required this.savingsGoals,
  });

  final List<Map<String, dynamic>> accounts;
  final List<Map<String, dynamic>> transactions;
  final List<Map<String, dynamic>> savingsGoals;

  factory MockSeed.fromJson(Map<String, dynamic> json) {
    return MockSeed(
      accounts: (json['accounts'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic item) => Map<String, dynamic>.from(item as Map))
          .toList(),
      transactions: (json['transactions'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic item) => Map<String, dynamic>.from(item as Map))
          .toList(),
      savingsGoals: (json['savingsGoals'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic item) => Map<String, dynamic>.from(item as Map))
          .toList(),
    );
  }
}

class MockSeedLoader {
  static Future<MockSeed> loadFromAsset() async {
    final String raw = await rootBundle.loadString('assets/mock/mock_data.json');
    final Map<String, dynamic> decoded =
        jsonDecode(raw) as Map<String, dynamic>;
    return MockSeed.fromJson(decoded);
  }
}
