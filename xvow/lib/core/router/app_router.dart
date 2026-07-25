import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/auth/presentation/sign_up_screen.dart';
import '../../features/bilan/presentation/bilan_screen.dart';
import '../../features/focus/presentation/focus_screen.dart';
import '../../features/payment/presentation/payment_info_screen.dart';
import '../../features/plan/presentation/create_objective_screen.dart';
import '../../features/plan/presentation/launch_week_screen.dart';
import '../../features/plan/presentation/plan_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/shell/presentation/app_shell.dart';
import '../services/auth_service.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final client = Supabase.instance.client;
  return GoRouter(
    initialLocation: '/auth/signin',
    refreshListenable: GoRouterRefreshStream(authUserChanges(client)),
    redirect: (context, state) {
      final user = ref.read(authUserProvider).asData?.value;
      final location = state.uri.toString();
      final isAuthRoute = location.startsWith('/auth');
      if (user == null && !isAuthRoute) {
        return '/auth/signin';
      }
      if (user != null && isAuthRoute) {
        return '/app/focus';
      }
      if (location == '/') {
        return user == null ? '/auth/signin' : '/app/focus';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SignInScreen()),
      GoRoute(
        path: '/auth/signin',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/auth/signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/app/focus',
                builder: (context, state) => const FocusScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/app/plan',
                builder: (context, state) => const PlanScreen(),
              ),
              GoRoute(
                path: '/app/plan/create-objective',
                builder: (context, state) => const CreateObjectiveScreen(),
              ),
              GoRoute(
                path: '/app/plan/launch',
                builder: (context, state) => const LaunchWeekScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/app/bilan',
                builder: (context, state) => const BilanScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/app/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/app/payment-info',
        builder: (context, state) => const PaymentInfoScreen(),
      ),
    ],
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _notify = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _notify;

  @override
  void dispose() {
    _notify.cancel();
    super.dispose();
  }
}
