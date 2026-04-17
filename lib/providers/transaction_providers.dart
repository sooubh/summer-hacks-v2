import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_fin_os/models/finance_enums.dart';
import 'package:student_fin_os/models/finance_transaction.dart';
import 'package:student_fin_os/providers/auth_providers.dart';
import 'package:student_fin_os/providers/firebase_providers.dart';

final transactionCategoriesProvider = Provider<List<String>>((ref) {
  return const <String>[
    'auto',
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
    String source = 'manual',
    String channel = 'cash',
  }) async {
    final String? userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      throw StateError('Not authenticated.');
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final DateTime now = DateTime.now().toUtc();
      final String normalizedCategory =
          category == 'auto' || category.trim().isEmpty
            ? _suggestCategory(title: title, type: type, tags: tags)
              : category;
      final FinanceTransaction tx = FinanceTransaction(
        id: ref.read(uuidProvider).v4(),
        userId: userId,
        accountId: accountId,
        title: title,
        amount: amount,
        type: type,
        category: normalizedCategory,
        tags: tags,
        note: note,
        source: source,
        channel: channel,
        isCategoryOverridden: category != 'auto' && category.trim().isNotEmpty,
        transactionAt: now,
        createdAt: now,
        updatedAt: now,
      );

      await ref.read(transactionServiceProvider).createTransaction(tx);
    });
  }

  Future<void> overrideCategory({
    required String transactionId,
    required String category,
  }) async {
    final String? userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      throw StateError('Not authenticated.');
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(transactionServiceProvider).overrideTransactionCategory(
            userId: userId,
            transactionId: transactionId,
            category: category,
          );
    });
  }
}

final transactionControllerProvider =
    AsyncNotifierProvider<TransactionController, void>(TransactionController.new);

String _suggestCategory({
  required String title,
  required TransactionType type,
  required List<String> tags,
}) {
  if (type == TransactionType.income) {
    return 'stipend';
  }

  final String text = '${title.toLowerCase()} ${tags.join(' ').toLowerCase()}';
  if (text.contains('rent') || text.contains('hostel')) {
    return 'rent';
  }
  if (text.contains('food') || text.contains('cafe') || text.contains('restaurant')) {
    return 'food';
  }
  if (text.contains('bus') || text.contains('metro') || text.contains('uber')) {
    return 'travel';
  }
  if (text.contains('book') || text.contains('course') || text.contains('tuition')) {
    return 'education';
  }
  if (text.contains('movie') || text.contains('netflix') || text.contains('game')) {
    return 'entertainment';
  }
  if (text.contains('medicine') || text.contains('clinic') || text.contains('hospital')) {
    return 'health';
  }
  if (text.contains('electricity') || text.contains('wifi') || text.contains('bill')) {
    return 'utilities';
  }
  if (text.contains('shop') || text.contains('mall') || text.contains('amazon')) {
    return 'shopping';
  }
  return 'misc';
}
