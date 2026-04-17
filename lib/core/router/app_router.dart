import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:student_fin_os/features/assistant/ui/chat_assistant_screen.dart';
import 'package:student_fin_os/features/auth/ui/login_screen.dart';
import 'package:student_fin_os/features/shell/ui/app_shell_screen.dart';
import 'package:student_fin_os/providers/firebase_providers.dart';

class AppRoutes {
  static const String login = '/login';
  static const String dashboard = '/app/dashboard';
  static const String accounts = '/app/accounts';
  static const String transactions = '/app/transactions';
  static const String splits = '/app/splits';
  static const String savings = '/app/savings';
  static const String insights = '/app/insights';
  static const String cashFlow = '/app/cashflow';
  static const String chatAssistant = '/assistant/chat';

  static const List<String> appTabs = <String>[
    dashboard,
    accounts,
    transactions,
    splits,
    savings,
    insights,
    cashFlow,
  ];

  static int indexFromLocation(String location) {
    final int idx = appTabs.indexOf(location);
    return idx < 0 ? 0 : idx;
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final GoRouterRefreshStream refreshNotifier = GoRouterRefreshStream(
    ref.watch(authServiceProvider).authStateChanges(),
  );
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: AppRoutes.dashboard,
    refreshListenable: refreshNotifier,
    routes: <GoRoute>[
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (BuildContext context, GoRouterState state) =>
            const LoginScreen(),
      ),
      GoRoute(
        path: '/app/:tab',
        name: 'app-tab',
        builder: (BuildContext context, GoRouterState state) {
          final String location =
              '/app/${state.pathParameters['tab'] ?? 'dashboard'}';
          return AppShellScreen(
            initialIndex: AppRoutes.indexFromLocation(location),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.chatAssistant,
        name: 'chat-assistant',
        builder: (BuildContext context, GoRouterState state) {
          return const ChatAssistantScreen();
        },
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final bool loggedIn = ref.read(firebaseAuthProvider).currentUser != null;
      final String location = state.matchedLocation;
      final bool isLoggingIn = location == AppRoutes.login;
      final bool inAppArea = location.startsWith('/app/');
      final bool inAssistantArea = location.startsWith('/assistant/');

      if (!loggedIn && !isLoggingIn) {
        return AppRoutes.login;
      }
      if (loggedIn && isLoggingIn) {
        return AppRoutes.dashboard;
      }
      if (loggedIn && !inAppArea && !inAssistantArea && !isLoggingIn) {
        return AppRoutes.dashboard;
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
