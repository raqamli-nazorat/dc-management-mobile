import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/workers')) return 1;
    if (location.startsWith('/departments')) return 2;
    if (location.startsWith('/expense-requests')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.smoke)),
        ),
        child: BottomNavigationBar(
          currentIndex: index,
          onTap: (i) {
            switch (i) {
              case 0: context.go('/dashboard');
              case 1: context.go('/workers');
              case 2: context.go('/departments');
              case 3: context.go('/expense-requests');
              case 4: context.go('/profile');
            }
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
            BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'Ishchilar'),
            BottomNavigationBarItem(icon: Icon(Icons.business_outlined), activeIcon: Icon(Icons.business), label: "Bo'limlar"),
            BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'Xarajatlar'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profil'),
          ],
        ),
      ),
    );
  }
}
