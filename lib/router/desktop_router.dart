import 'package:go_router/go_router.dart';
import '../presentation/screens/desktop/desktop_shell_screen.dart';
import '../presentation/screens/desktop/desktop_request_screen.dart';
import '../presentation/screens/mobile/environment_screen.dart';
import '../presentation/screens/mobile/profile_screen.dart';

final desktopRouter = GoRouter(
  initialLocation: '/request',
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return DesktopShellScreen(child: child);
      },
      routes: [
        GoRoute(
          path: '/request',
          builder: (context, state) => const DesktopRequestScreen(),
        ),
        GoRoute(
          path: '/environments',
          builder: (context, state) => const EnvironmentScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
  ],
);
