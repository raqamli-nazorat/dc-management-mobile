import 'package:flutter/material.dart';
import 'package:dcmanagement/app_config.dart';
import 'package:dcmanagement/screens/expense_request_form_screen.dart';
import 'package:dcmanagement/screens/my_requests_screen.dart';
import 'package:dcmanagement/screens/project_list_screen.dart';
import 'package:dcmanagement/screens/task_list_screen.dart';
import 'package:dcmanagement/screens/reports_screen.dart';
import 'package:dcmanagement/screens/worker_my_requests_screen.dart';
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
import 'package:dcmanagement/screens/user_filter_screen.dart';
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
    if (!kProduction) return onLogin ? '/home' : null;
    if (onLogin) return PinSession.instance.verified ? '/home' : '/pin';
    if (!onPin && !PinSession.instance.verified) return '/pin';
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/pin', builder: (context, state) => const PinScreen()),

    // /users/filter — /users/:id DAN OLDIN bo'lishi shart
    GoRoute(
      path: '/users/filter',
      builder: (context, state) {
        final args = state.extra as Map<String, dynamic>;
        return UserFilterScreen(
          initial: args['filter'] as UserFilter,
          availableRoles: (args['roles'] as List).cast<String>(),
        );
      },
    ),
    GoRoute(
      path: '/users/:id',
      builder: (context, state) =>
          UserDetailScreen(userId: int.parse(state.pathParameters['id']!)),
    ),

    // Projects sub screens
    GoRoute(
      path: '/projects/list',
      builder: (_, __) => const ProjectListScreen(),
    ),
    GoRoute(
      path: '/projects/tasks',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final project = extra?['project'] as Map<String, dynamic>?;
        return TaskListScreen(project: project);
      },
    ),
    GoRoute(
      path: '/projects/meetings',
      builder: (_, __) => const Scaffold(
        body: Center(child: Text("Yig'ilishlar — tez orada")),
      ),
    ),
    GoRoute(
      path: '/projects/my-meetings',
      builder: (_, __) => const Scaffold(
        body: Center(child: Text("Mening yig'ilishlarim — tez orada")),
      ),
    ),

    // Finance sub screens
    GoRoute(
      path: '/finance/expense-requests',
      builder: (_, __) => const ExpenseRequestsScreen(),
    ),
    GoRoute(
      path: '/finance/expense-request-form',
      builder: (_, __) => const ExpenseRequestFormScreen(),
    ),
    GoRoute(path: '/finance/salary', builder: (_, __) => const SalaryScreen()),
    GoRoute(
      path: '/finance/history',
      builder: (_, __) => const FinanceHistoryScreen(),
    ),
    GoRoute(
      path: '/finance/my-requests',
      builder: (_, __) => const MyRequestsScreen(),
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
        GoRoute(path: '/my-requests', builder: (_, __) => const WorkerMyRequestsScreen()),
        GoRoute(path: '/reports', builder: (_, __) => const ReportsScreen()),
      ],
    ),
  ],
);