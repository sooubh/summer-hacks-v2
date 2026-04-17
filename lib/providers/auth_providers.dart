import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_fin_os/providers/firebase_providers.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges();
});

final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).value?.uid;
});

class AuthController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final credential = await ref.read(authServiceProvider).signInWithGoogle();
      final String? userId = credential.user?.uid;
      if (userId != null && userId.isNotEmpty) {
        await ref.read(mockBankServiceProvider).seedStarterData(userId);
      }
    });
  }

  Future<void> requestOtp(String email) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authServiceProvider).requestEmailOtp(email: email);
    });
  }

  Future<void> verifyOtp({required String email, required String otp}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final credential = await ref
          .read(authServiceProvider)
          .verifyEmailOtp(email: email, otp: otp);
      final String? userId = credential.user?.uid;
      if (userId != null && userId.isNotEmpty) {
        await ref.read(mockBankServiceProvider).seedStarterData(userId);
      }
    });
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authServiceProvider).signOut();
    });
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, void>(AuthController.new);
