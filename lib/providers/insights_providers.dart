import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_fin_os/models/ai_insight.dart';
import 'package:student_fin_os/providers/auth_providers.dart';
import 'package:student_fin_os/providers/dashboard_providers.dart';
import 'package:student_fin_os/providers/firebase_providers.dart';

final insightsFeedProvider = StreamProvider.autoDispose<List<AiInsight>>((ref) {
  final String? userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return Stream<List<AiInsight>>.value(const <AiInsight>[]);
  }

  return ref.watch(insightsServiceProvider).watchInsights(userId);
});

final automatedInsightsProvider = Provider.autoDispose<List<AiInsight>>((ref) {
  final String? userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return const <AiInsight>[];
  }

  final transactions = ref.watch(transactionsProvider).value ?? const [];
  final snapshot = ref.watch(dashboardSnapshotProvider);

  return ref.read(insightsServiceProvider).generateRuleBasedInsights(
        userId: userId,
        recentTransactions: transactions,
        totalBalance: snapshot.totalBalance,
        safeToSpend: snapshot.safeToSpend,
      );
});

class InsightsController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> refreshRuleBasedInsights() async {
    final String? userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      return;
    }

    final transactions = ref.read(transactionsProvider).value ?? const [];
    final snapshot = ref.read(dashboardSnapshotProvider);

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final generated = ref.read(insightsServiceProvider).generateRuleBasedInsights(
            userId: userId,
            recentTransactions: transactions,
            totalBalance: snapshot.totalBalance,
            safeToSpend: snapshot.safeToSpend,
          );
      await ref.read(insightsServiceProvider).persistInsights(userId, generated);
    });
  }
}

final insightsControllerProvider =
    AsyncNotifierProvider<InsightsController, void>(InsightsController.new);
