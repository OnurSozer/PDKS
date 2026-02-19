import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/constants/app_constants.dart';
import 'core/l10n/app_localizations.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/sessions/screens/session_history_screen.dart';
import 'features/sessions/screens/session_detail_screen.dart';
import 'features/records/screens/records_screen.dart';
import 'features/leave/screens/leave_screen.dart';
import 'features/leave/screens/record_leave_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/profile/screens/schedule_view_screen.dart';

// Locale provider for language switching
final localeProvider = StateProvider<Locale>((ref) => const Locale('tr'));

// First day of week provider: 1 = Monday (default), 7 = Sunday
final firstDayOfWeekProvider = StateProvider<int>((ref) => 1);

/// Bridges Riverpod auth state changes to a [ChangeNotifier] so GoRouter
/// can re-evaluate its redirect without being fully recreated.
class _AuthNotifierBridge extends ChangeNotifier {
  _AuthNotifierBridge(Ref ref) {
    ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }
}

final _authNotifierBridgeProvider = Provider<_AuthNotifierBridge>((ref) {
  return _AuthNotifierBridge(ref);
});

// Navigation shell
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(_authNotifierBridgeProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);

      // While auth is loading (restoring session), stay on current route
      if (authState.isLoading) return null;

      final isLoggedIn = authState.isAuthenticated;
      final isLoginRoute = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoginRoute) return '/login';
      if (isLoggedIn && isLoginRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return _MainShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/calendar',
            builder: (context, state) => const SessionHistoryScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final session = state.extra as Map<String, dynamic>?;
                  if (session == null) {
                    return const Scaffold(
                      body: Center(child: Text('Session not found')),
                    );
                  }
                  return SessionDetailScreen(session: session);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/records',
            builder: (context, state) => const RecordsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
            routes: [
              GoRoute(
                path: 'schedule',
                builder: (context, state) => const ScheduleViewScreen(),
              ),
              GoRoute(
                path: 'leave',
                builder: (context, state) => const LeaveScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (context, state) => const RecordLeaveScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class _MainShell extends StatelessWidget {
  final Widget child;

  const _MainShell({required this.child});

  static int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/calendar')) return 1;
    if (location.startsWith('/records')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppConstants.backgroundColor,
          border: Border(
            top: BorderSide(color: AppConstants.borderColor, width: 0.5),
          ),
        ),
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) {
            switch (index) {
              case 0:
                context.go('/home');
              case 1:
                context.go('/calendar');
              case 2:
                context.go('/records');
              case 3:
                context.go('/profile');
            }
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home_rounded),
              label: l10n.home,
            ),
            NavigationDestination(
              icon: const Icon(Icons.calendar_today_outlined),
              selectedIcon: const Icon(Icons.calendar_today),
              label: l10n.calendar,
            ),
            NavigationDestination(
              icon: const Icon(Icons.bar_chart_outlined),
              selectedIcon: const Icon(Icons.bar_chart_rounded),
              label: l10n.statistics,
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outlined),
              selectedIcon: const Icon(Icons.person),
              label: l10n.profile,
            ),
          ],
        ),
      ),
    );
  }
}
