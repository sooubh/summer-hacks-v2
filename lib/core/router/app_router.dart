import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:student_fin_os/features/auth/ui/login_screen.dart';
import 'package:student_fin_os/features/shell/ui/app_shell_screen.dart';
import 'package:student_fin_os/providers/firebase_providers.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final GoRouterRefreshStream refreshNotifier =
      GoRouterRefreshStream(ref.watch(authServiceProvider).authStateChanges());
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: '/app',
    refreshListenable: refreshNotifier,
    routes: <GoRoute>[
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (BuildContext context, GoRouterState state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/app',
        name: 'app',
        builder: (BuildContext context, GoRouterState state) => const AppShellScreen(),
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final bool loggedIn = ref.read(firebaseAuthProvider).currentUser != null;
      final bool isLoggingIn = state.matchedLocation == '/login';

      if (!loggedIn && !isLoggingIn) {
        return '/login';
      }
      if (loggedIn && isLoggingIn) {
        return '/app';
      }
      return null;
    },
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((dynamic _) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
