import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../features/auth/model/auth_notifier.dart';
import '../../pages/auth/ui/auth_page.dart';
import '../../pages/dashboard/ui/dashboard_page.dart';
import '../../pages/workers/ui/workers_page.dart';
import '../../pages/departments/ui/departments_page.dart';
import '../../pages/profile/ui/profile_page.dart';
import '../../pages/expense_requests/ui/expense_requests_page.dart';
import '../../features/expense_request_create/ui/expense_request_create_page.dart';
import '../../widgets/app_shell/app_shell.dart';
import 'route_names.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final isAuthenticated = authState is AuthAuthenticated;
      final isOnAuth = state.matchedLocation == '/auth';

      if (!isAuthenticated && !isOnAuth) return '/auth';
      if (isAuthenticated && isOnAuth) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/auth',
        name: RouteNames.auth,
        builder: (context, state) => const AuthPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            name: RouteNames.dashboard,
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: '/workers',
            name: RouteNames.workers,
            builder: (context, state) => const WorkersPage(),
          ),
          GoRoute(
            path: '/departments',
            name: RouteNames.departments,
            builder: (context, state) => const DepartmentsPage(),
          ),
          GoRoute(
            path: '/profile',
            name: RouteNames.profile,
            builder: (context, state) => const ProfilePage(),
          ),
          GoRoute(
            path: '/expense-requests',
            name: RouteNames.expenseRequests,
            builder: (context, state) => const ExpenseRequestsPage(),
          ),
        ],
      ),
      GoRoute(
        path: '/expense-requests/new',
        name: RouteNames.expenseRequestCreate,
        builder: (context, state) => const ExpenseRequestCreatePage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Center(
        child: Text(
          '404 — Sahifa topilmadi',
          style: const TextStyle(color: Color(0xFFF0F0F0)),
        ),
      ),
    ),
  );
});
