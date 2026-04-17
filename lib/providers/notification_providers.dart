import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_fin_os/providers/auth_providers.dart';
import 'package:student_fin_os/providers/firebase_providers.dart';

final notificationPreferencesProvider = StreamProvider.autoDispose<Map<String, dynamic>>((ref) {
  final String? userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return Stream<Map<String, dynamic>>.value(const <String, dynamic>{});
  }

  return ref.watch(notificationServiceProvider).watchPreferences(userId);
});

class NotificationController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> setDailyReminder({
    required bool enabled,
    required String localTime,
  }) async {
    final String? userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(notificationServiceProvider).upsertDailyReminder(
            userId: userId,
            enabled: enabled,
            localTime: localTime,
          );
    });
  }

  Future<void> setBudgetAlert({
    required bool enabled,
    required double monthlyLimit,
  }) async {
    final String? userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(notificationServiceProvider).upsertBudgetAlert(
            userId: userId,
            enabled: enabled,
            monthlyLimit: monthlyLimit,
          );
    });
  }
}

final notificationControllerProvider =
    AsyncNotifierProvider<NotificationController, void>(NotificationController.new);
