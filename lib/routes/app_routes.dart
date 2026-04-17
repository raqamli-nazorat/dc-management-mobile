import 'package:dcmanagement/screens/expense_requests_screen.dart';
import 'package:dcmanagement/screens/finance_history_screen.dart';
import 'package:dcmanagement/screens/finance_screen.dart';
import 'package:dcmanagement/screens/home_screen.dart';
import 'package:dcmanagement/screens/role_select_screen.dart';
import 'package:dcmanagement/screens/salary_screen.dart';
import 'package:dcmanagement/screens/pin_lock_screen.dart';
import 'package:dcmanagement/screens/profile_screen.dart';
import 'package:dcmanagement/screens/project_screen.dart';
import 'package:dcmanagement/screens/user_detail_screen.dart';
import 'package:dcmanagement/screens/users_scree.dart';
import 'package:dcmanagement/services/auth_service.dart';
import 'package:dcmanagement/services/pin_session.dart';
import 'package:dcmanagement/widgets/scaffils_with_nav.dart';
import 'package:go_router/go_router.dart';
import 'package:dcmanagement/screens/login_screen.dart';

// ... yuqoridagi importlar ...

final _authService = AuthService();

final appRouter = GoRouter(
  initialLocation: '/login',
  refreshListenable: PinSession.instance,
  redirect: (context, state) async {
    final loggedIn = await _authService.isLoggedIn();
    final location = state.matchedLocation;
    final onLogin = location == '/login';
    final onPin = location == '/pin';

    if (!loggedIn) return onLogin ? null : '/login';
    if (onLogin) return '/pin';
    if (!onPin && !PinSession.instance.verified) return '/pin';
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/pin', builder: (context, state) => const PinScreen()),

    GoRoute(
      path: '/users/:id',
      builder: (context, state) =>
          UserDetailScreen(userId: int.parse(state.pathParameters['id']!)),
    ),

    // Finance sub screens
    GoRoute(
      path: '/finance/expense-requests',
      builder: (_, __) => const ExpenseRequestsScreen(),
    ),
    GoRoute(path: '/finance/salary', builder: (_, __) => const SalaryScreen()),
    GoRoute(
      path: '/finance/history',
      builder: (_, __) => const FinanceHistoryScreen(),
    ),

    // Select Role — Bottom bar bo'lmasligi uchun alohida
    GoRoute(
      path: '/select-role',
      builder: (context, state) => const RoleSelectScreen(),
    ),

    // ==================== ShellRoute (Bottom Navigation Bar bilan sahifalar) ====================
    ShellRoute(
      builder: (context, state, child) =>
          ScaffoldWithNavBar(location: state.uri.path, child: child),
      routes: [
        GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/projects', builder: (_, __) => const ProjectsScreen()),
        GoRoute(path: '/users', builder: (_, __) => const UsersScreen()),
        GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        GoRoute(path: '/finance', builder: (_, __) => const FinanceScreen()),
      ],
    ),
  ],
);
