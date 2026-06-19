import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../presentation/screens/mobile/shell_screen.dart';
import '../presentation/screens/mobile/request_screen.dart';
import '../presentation/screens/mobile/collection_screen.dart';
import '../presentation/screens/mobile/environment_screen.dart';
import '../presentation/screens/mobile/profile_screen.dart';
import '../presentation/screens/mobile/auth_screen.dart';
import '../presentation/screens/mobile/import_screen.dart';
import '../presentation/screens/mobile/runner_screen.dart';

final mobileRouter = GoRouter(
  initialLocation: '/request',
  redirect: (context, state) {
    final isLoggedIn = Supabase.instance.client.auth.currentUser != null;
    final isAuthRoute = state.matchedLocation == '/auth';

    if (!isLoggedIn && !isAuthRoute) {
      return '/auth';
    }

    if (isLoggedIn && isAuthRoute) {
      return '/request';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthScreen(),
    ),
    GoRoute(
      path: '/import',
      builder: (context, state) => const ImportScreen(),
    ),
    GoRoute(
      path: '/runner/:id',
      builder: (context, state) => RunnerScreen(
        collectionId: state.pathParameters['id']!,
      ),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ShellScreen(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/request',
              builder: (context, state) => const RequestScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/collections',
              builder: (context, state) => const CollectionScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/environments',
              builder: (context, state) => const EnvironmentScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
