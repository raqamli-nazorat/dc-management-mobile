import 'package:dcmanagement/screens/home_screen.dart';
import 'package:dcmanagement/screens/profile_screen.dart';
import 'package:dcmanagement/screens/project_screen.dart';
import 'package:dcmanagement/screens/users_scree.dart';
import 'package:dcmanagement/widgets/scaffils_with_nav.dart';
import 'package:go_router/go_router.dart';
import 'package:dcmanagement/screens/login_screen.dart';
import 'package:dcmanagement/services/auth_service.dart';

final _authService = AuthService();

final appRouter = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) async {
    final loggedIn = await _authService.isLoggedIn();
    final onLogin = state.matchedLocation == '/login';

    if (!loggedIn && !onLogin) return '/login';
    if (loggedIn && onLogin) return '/home';
    return null; // o'zgartirma
  },
  routes: [
    // Login — ShellRoute dan TASHQARIDA, bottom bar yo'q
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),

    // ShellRoute — bottom bar bor sahifalar
    ShellRoute(
      builder: (context, state, child) =>
          ScaffoldWithNavBar(child: child), // child = joriy sahifa
      routes: [
        GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/projects',
          builder: (context, state) => const ProjectsScreen(),
        ),
        //         GoRoute(
        //   path: '/reports',
        //   builder: (context, state) => const ReportsScreen(),
        // ),
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
