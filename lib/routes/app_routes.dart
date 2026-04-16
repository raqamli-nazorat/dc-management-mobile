import 'package:dcmanagement/screens/home_screen.dart';
import 'package:dcmanagement/screens/pin_lock_screen.dart';
import 'package:dcmanagement/screens/profile_screen.dart';
import 'package:dcmanagement/screens/project_screen.dart';
import 'package:dcmanagement/screens/user_detail_screen.dart';
import 'package:dcmanagement/screens/users_scree.dart';
import 'package:dcmanagement/services/auth_service.dart';
import 'package:dcmanagement/services/pin_session.dart';
import 'package:dcmanagement/services/storage_service.dart';
import 'package:dcmanagement/widgets/scaffils_with_nav.dart';
import 'package:go_router/go_router.dart';
import 'package:dcmanagement/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _authService = AuthService();

final appRouter = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) async {
    final loggedIn = await _authService.isLoggedIn();
    final location = state.matchedLocation;
    final onLogin = location == '/login';
    final onPin = location == '/pin';

    if (!loggedIn) return onLogin ? null : '/login';

    if (onLogin) return '/pin'; // login bo'lsa ham PIN so'ra

    if (!onPin && !PinSession.instance.verified) return '/pin';

    return null;
  },
  routes: [
    // Login — no bottom bar
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),

    // PIN lock — full screen, no bottom bar
    GoRoute(path: '/pin', builder: (context, state) => const PinScreen()),

    // User detail — full screen, no bottom bar
    GoRoute(
      path: '/users/:id',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return UserDetailScreen(userId: id);
      },
    ),

    // ShellRoute — screens with bottom bar
    ShellRoute(
      builder: (context, state, child) => ScaffoldWithNavBar(child: child),
      routes: [
        GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/projects',
          builder: (context, state) => const ProjectsScreen(),
        ),
        GoRoute(
          path: '/users',
          builder: (context, state) => const UsersScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
  ],
);
