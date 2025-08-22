import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../screens/main_layout.dart';
import '../screens/dashboard_screen.dart';
import '../screens/enhanced_ai_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/domains/events_screen.dart';
import '../screens/domains/meals_screen.dart';
import '../screens/domains/journals_screen.dart';
import '../screens/domains/health_screen.dart';
import '../screens/domains/finance_screen.dart';
import '../screens/domains/education_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/dashboard',
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return MainLayout(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/ai-enhanced',
            name: 'ai-enhanced',
            builder: (context, state) => const EnhancedAIScreen(),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          
          // Domain screens
          GoRoute(
            path: '/events',
            name: 'events',
            builder: (context, state) => const EventsScreen(),
          ),
          GoRoute(
            path: '/meals',
            name: 'meals',
            builder: (context, state) => const MealsScreen(),
          ),
          GoRoute(
            path: '/journals',
            name: 'journals',
            builder: (context, state) => const JournalsScreen(),
          ),
          GoRoute(
            path: '/health',
            name: 'health',
            builder: (context, state) => const HealthScreen(),
          ),
          GoRoute(
            path: '/finance',
            name: 'finance',
            builder: (context, state) => const FinanceScreen(),
          ),
          GoRoute(
            path: '/education',
            name: 'education',
            builder: (context, state) => const EducationScreen(),
          ),
        ],
      ),
    ],
  );
});
