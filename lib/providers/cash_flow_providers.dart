import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_fin_os/models/cash_flow_point.dart';
import 'package:student_fin_os/providers/dashboard_providers.dart';
import 'package:student_fin_os/providers/firebase_providers.dart';

final cashFlowProjectionProvider = Provider<List<CashFlowPoint>>((ref) {
  final snapshot = ref.watch(dashboardSnapshotProvider);
  final transactions = ref.watch(transactionsProvider).value ?? const [];

  return ref.watch(cashFlowServiceProvider).project(
        openingBalance: snapshot.totalBalance,
        recentTransactions: transactions,
        days: 14,
      );
});

final predictedLowBalanceDateProvider = Provider<DateTime?>((ref) {
  return ref.watch(cashFlowServiceProvider).predictedLowBalanceDate(
        ref.watch(cashFlowProjectionProvider),
      );
});
