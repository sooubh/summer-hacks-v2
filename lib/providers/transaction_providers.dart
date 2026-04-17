import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_fin_os/models/finance_enums.dart';
import 'package:student_fin_os/models/finance_transaction.dart';
import 'package:student_fin_os/providers/auth_providers.dart';
import 'package:student_fin_os/providers/firebase_providers.dart';

final transactionCategoriesProvider = Provider<List<String>>((ref) {
  return const <String>[
    'food',
    'rent',
    'travel',
    'education',
    'shopping',
    'utilities',
    'entertainment',
    'health',
    'freelance',
    'stipend',
    'misc',
  ];
});

class TransactionController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> addManualTransaction({
    required String title,
    required String accountId,
    required double amount,
    required TransactionType type,
    required String category,
    required List<String> tags,
    String? note,
  }) async {
    final String? userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      throw StateError('Not authenticated.');
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final DateTime now = DateTime.now().toUtc();
      final FinanceTransaction tx = FinanceTransaction(
        id: ref.read(uuidProvider).v4(),
        userId: userId,
        accountId: accountId,
        title: title,
        amount: amount,
        type: type,
        category: category,
        tags: tags,
        note: note,
        source: 'manual',
        transactionAt: now,
        createdAt: now,
        updatedAt: now,
      );

      await ref.read(transactionServiceProvider).createTransaction(tx);
    });
  }
}

final transactionControllerProvider =
    AsyncNotifierProvider<TransactionController, void>(TransactionController.new);
