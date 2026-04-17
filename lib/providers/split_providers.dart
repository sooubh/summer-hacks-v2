import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_fin_os/models/finance_enums.dart';
import 'package:student_fin_os/models/split_expense.dart';
import 'package:student_fin_os/models/split_group.dart';
import 'package:student_fin_os/providers/auth_providers.dart';
import 'package:student_fin_os/providers/firebase_providers.dart';

final selectedSplitGroupIdProvider = StateProvider<String?>((ref) {
  return null;
});

final splitGroupsProvider = StreamProvider.autoDispose<List<SplitGroup>>((ref) {
  final String? userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return Stream<List<SplitGroup>>.value(const <SplitGroup>[]);
  }
  return ref.watch(splitServiceProvider).watchGroups(userId);
});

final splitExpensesProvider = StreamProvider.autoDispose<List<SplitExpense>>((ref) {
  final String? userId = ref.watch(currentUserIdProvider);
  final String? groupId = ref.watch(selectedSplitGroupIdProvider);
  if (userId == null || groupId == null) {
    return Stream<List<SplitExpense>>.value(const <SplitExpense>[]);
  }

  return ref.watch(splitServiceProvider).watchGroupExpenses(
        userId: userId,
        groupId: groupId,
      );
});

final splitNetBalancesProvider = Provider<Map<String, double>>((ref) {
  final List<SplitGroup> groups = ref.watch(splitGroupsProvider).value ?? const <SplitGroup>[];
  final List<SplitExpense> expenses =
      ref.watch(splitExpensesProvider).value ?? const <SplitExpense>[];
  final String? selectedGroupId = ref.watch(selectedSplitGroupIdProvider);

  if (selectedGroupId == null) {
    return const <String, double>{};
  }

  SplitGroup? selectedGroup;
  for (final SplitGroup group in groups) {
    if (group.id == selectedGroupId) {
      selectedGroup = group;
      break;
    }
  }

  if (selectedGroup == null) {
    return const <String, double>{};
  }

  return ref.watch(splitServiceProvider).netBalances(expenses, selectedGroup.memberIds);
});

class SplitController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> createGroup({
    required String name,
    required List<String> memberIds,
    String? description,
  }) async {
    final String? userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      throw StateError('Not authenticated.');
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final DateTime now = DateTime.now().toUtc();
      final SplitGroup group = SplitGroup(
        id: ref.read(uuidProvider).v4(),
        ownerId: userId,
        name: name,
        memberIds: memberIds,
        description: description,
        createdAt: now,
        updatedAt: now,
      );
      await ref.read(splitServiceProvider).createGroup(userId, group);
    });
  }

  Future<void> addExpense({
    required String groupId,
    required String title,
    required double totalAmount,
    required String paidBy,
    required Map<String, double> owedBy,
  }) async {
    final String? userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      throw StateError('Not authenticated.');
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final DateTime now = DateTime.now().toUtc();
      final SplitExpense expense = SplitExpense(
        id: ref.read(uuidProvider).v4(),
        groupId: groupId,
        createdBy: userId,
        title: title,
        totalAmount: totalAmount,
        currency: 'INR',
        paidBy: paidBy,
        owedBy: owedBy,
        status: SplitStatus.pending,
        expenseAt: now,
        createdAt: now,
        updatedAt: now,
      );
      await ref.read(splitServiceProvider).addGroupExpense(userId, expense);
    });
  }

  Future<void> markExpenseSettled(String expenseId) async {
    final String? userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      throw StateError('Not authenticated.');
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(splitServiceProvider).markSettled(
            userId: userId,
            expenseId: expenseId,
          );
    });
  }
}

final splitControllerProvider =
    AsyncNotifierProvider<SplitController, void>(SplitController.new);
