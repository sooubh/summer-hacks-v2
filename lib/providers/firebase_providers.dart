import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:student_fin_os/services/account_service.dart';
import 'package:student_fin_os/services/aggregator_service.dart';
import 'package:student_fin_os/services/auth_service.dart';
import 'package:student_fin_os/services/cash_flow_service.dart';
import 'package:student_fin_os/services/insights_service.dart';
import 'package:student_fin_os/services/mock_bank_service.dart';
import 'package:student_fin_os/services/notification_service.dart';
import 'package:student_fin_os/services/savings_service.dart';
import 'package:student_fin_os/services/split_service.dart';
import 'package:student_fin_os/services/transaction_service.dart';
import 'package:student_fin_os/services/simulation_service.dart';
import 'package:uuid/uuid.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final firebaseFunctionsProvider = Provider<FirebaseFunctions>((ref) {
  return FirebaseFunctions.instance;
});

final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn();
});

final uuidProvider = Provider<Uuid>((ref) {
  return const Uuid();
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    auth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
    functions: ref.watch(firebaseFunctionsProvider),
    googleSignIn: ref.watch(googleSignInProvider),
  );
});

final accountServiceProvider = Provider<AccountService>((ref) {
  return AccountService(ref.watch(firestoreProvider));
});

final transactionServiceProvider = Provider<TransactionService>((ref) {
  return TransactionService(ref.watch(firestoreProvider));
});

final aggregatorServiceProvider = Provider<AggregatorService>((ref) {
  return AggregatorService(ref.watch(firestoreProvider));
});

final simulationServiceProvider = Provider<SimulationService>((ref) {
  return SimulationService(
    accountService: ref.watch(accountServiceProvider),
    transactionService: ref.watch(transactionServiceProvider),
    uuid: ref.watch(uuidProvider),
  );
});

final splitServiceProvider = Provider<SplitService>((ref) {
  return SplitService(ref.watch(firestoreProvider));
});

final savingsServiceProvider = Provider<SavingsService>((ref) {
  return SavingsService(ref.watch(firestoreProvider));
});

final insightsServiceProvider = Provider<InsightsService>((ref) {
  return InsightsService(ref.watch(firestoreProvider), ref.watch(uuidProvider));
});

final cashFlowServiceProvider = Provider<CashFlowService>((ref) {
  return CashFlowService();
});

final mockBankServiceProvider = Provider<MockBankService>((ref) {
  return MockBankService(ref.watch(firestoreProvider), ref.watch(uuidProvider));
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref.watch(firestoreProvider));
});
