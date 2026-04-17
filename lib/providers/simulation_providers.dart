import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_fin_os/models/account.dart';
import 'package:student_fin_os/models/finance_enums.dart';
import 'package:student_fin_os/providers/auth_providers.dart';
import 'package:student_fin_os/providers/dashboard_providers.dart';
import 'package:student_fin_os/providers/firebase_providers.dart';

class SimulationController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> seedVirtualAccounts() async {
    final String? userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      throw StateError('Not authenticated.');
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final List<Account> existing = ref.read(accountsProvider).value ?? const <Account>[];
      await ref.read(simulationServiceProvider).seedVirtualAccountsIfEmpty(
            userId: userId,
            existingAccounts: existing,
          );
    });
  }

  Future<void> simulateCredit({required String accountId, double amount = 2000}) async {
    final String? userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      throw StateError('Not authenticated.');
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(simulationServiceProvider).simulateCredit(
            userId: userId,
            accountId: accountId,
            amount: amount,
          );
    });
  }

  Future<void> simulateDebit({required String accountId, double amount = 420}) async {
    final String? userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      throw StateError('Not authenticated.');
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(simulationServiceProvider).simulateDebit(
            userId: userId,
            accountId: accountId,
            amount: amount,
          );
    });
  }

  Future<void> simulateUpiPayment({required String accountId, double amount = 240}) async {
    final String? userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      throw StateError('Not authenticated.');
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(simulationServiceProvider).simulateUpiPayment(
            userId: userId,
            accountId: accountId,
            amount: amount,
          );
    });
  }

  Future<void> generateMockTransactions({int count = 8}) async {
    final String? userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      throw StateError('Not authenticated.');
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final List<Account> accounts = ref.read(accountsProvider).value ?? const <Account>[];
      await ref.read(simulationServiceProvider).generateMockTransactions(
            userId: userId,
            accounts: accounts,
            count: count,
          );
    });
  }

  Future<void> bootstrapUnifiedPlatform({
    int mockCount = 12,
  }) async {
    final String? userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      throw StateError('Not authenticated.');
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final List<Account> existing = ref.read(accountsProvider).value ?? const <Account>[];
      final List<Account> available =
          await ref.read(simulationServiceProvider).seedVirtualAccountsIfEmpty(
                userId: userId,
                existingAccounts: existing,
              );

      final List<Account> seedAccounts = available.isEmpty ? existing : available;
      await ref.read(simulationServiceProvider).generateMockTransactions(
            userId: userId,
            accounts: seedAccounts,
            count: mockCount,
          );
    });
  }
}

final simulationControllerProvider =
    AsyncNotifierProvider<SimulationController, void>(SimulationController.new);

final autoCategoryProvider = Provider<String Function(String, TransactionType, List<String>)>((
  Ref ref,
) {
  return (String title, TransactionType type, List<String> tags) {
    return ref
        .read(simulationServiceProvider)
        .suggestCategory(title: title, type: type, tags: tags);
  };
});
