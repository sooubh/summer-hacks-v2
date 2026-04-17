import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_fin_os/models/finance_enums.dart';
import 'package:student_fin_os/models/savings_goal.dart';
import 'package:student_fin_os/providers/auth_providers.dart';
import 'package:student_fin_os/providers/dashboard_providers.dart';
import 'package:student_fin_os/providers/firebase_providers.dart';

final safeToSpendProvider = Provider<double>((ref) {
  return ref.watch(dashboardSnapshotProvider).safeToSpend;
});

class SavingsController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> createGoal({
    required String title,
    required double targetAmount,
    required DateTime deadline,
    int priority = 1,
  }) async {
    final String? userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      throw StateError('Not authenticated.');
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final DateTime now = DateTime.now().toUtc();
      final SavingsGoal goal = SavingsGoal(
        id: ref.read(uuidProvider).v4(),
        userId: userId,
        title: title,
        targetAmount: targetAmount,
        savedAmount: 0,
        deadline: deadline,
        status: GoalStatus.active,
        priority: priority,
        createdAt: now,
        updatedAt: now,
      );

      await ref.read(savingsServiceProvider).upsertGoal(goal);
    });
  }

  Future<void> addContribution({
    required String goalId,
    required double amount,
  }) async {
    final String? userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      throw StateError('Not authenticated.');
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(savingsServiceProvider).contributeToGoal(
            userId: userId,
            goalId: goalId,
            amount: amount,
          );
    });
  }
}

final savingsControllerProvider =
    AsyncNotifierProvider<SavingsController, void>(SavingsController.new);
