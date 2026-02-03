import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/home_screen.dart';
import '../../features/tasks/tasks_screen.dart';
import '../../features/health/health_screen.dart';
import '../../features/insights/insights_screen.dart';
import '../../features/settings/settings_screen.dart';

/// App route paths
class AppRoutes {
  static const String home = '/';
  static const String tasks = '/tasks';
  static const String health = '/health';
  static const String insights = '/insights';
  static const String settings = '/settings';
}

/// Main app router configuration
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    // Shell route for bottom navigation
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(navigationShell: navigationShell);
      },
      branches: [
        // Home branch
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        // Tasks branch
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.tasks,
              builder: (context, state) => const TasksScreen(),
            ),
          ],
        ),
        // Health branch
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.health,
              builder: (context, state) => const HealthScreen(),
            ),
          ],
        ),
        // Insights branch
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.insights,
              builder: (context, state) => const InsightsScreen(),
            ),
          ],
        ),
        // Settings branch
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.settings,
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);

/// App shell with bottom navigation
class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        backgroundColor: const Color(0xFF34195B),
        indicatorColor: const Color(0xFF540CC3),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.task_outlined),
            selectedIcon: Icon(Icons.task),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite),
            label: 'Health',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Insights',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
