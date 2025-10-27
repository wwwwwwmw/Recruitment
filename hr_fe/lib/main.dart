import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'services/auth_state.dart';
import 'services/notifications_state.dart';

// Screens
import 'screens/role_dashboard.dart';
import 'screens/my_profile_screen.dart';
import 'screens/jobs_screen.dart';
import 'screens/job_detail_screen.dart';
import 'screens/applications_screen.dart';
import 'screens/application_detail_screen.dart';
import 'screens/evaluations_screen.dart';
import 'screens/interviews_screen.dart';
import 'screens/offers_screen.dart';
import 'screens/results_screen.dart';
import 'screens/users_screen.dart';
import 'screens/criteria_admin_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/processes_screen.dart';
import 'screens/committees_screen.dart';
import 'screens/my_candidates_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/notifications_screen.dart';
import 'theme/app_theme.dart';

void main() => runApp(const HRApp());

class HRApp extends StatelessWidget {
  const HRApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthState()),
        ChangeNotifierProvider(create: (_) => NotificationsState()),
      ],
      child: Builder(
        builder: (context) {
          final auth = context.watch<AuthState>();
          final router = GoRouter(
            refreshListenable: auth,
            redirect: (ctx, state) {
              final loggedIn = auth.isLoggedIn;
              final loggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/signup';
              if (!loggedIn && !loggingIn) return '/login';
              if (loggedIn && loggingIn) return '/';
              return null;
            },
            routes: [
              GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
              GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
              GoRoute(path: '/', builder: (_, __) => const RoleDashboard()),
              GoRoute(path: '/my-profile', builder: (_, __) => const MyProfileScreen()),
              GoRoute(path: '/criteria', builder: (_, __) => const CriteriaAdminScreen()),
              GoRoute(path: '/my-candidates', builder: (_, __) => const MyCandidatesScreen()),
              GoRoute(path: '/jobs', builder: (_, __) => const JobsScreen()),
              GoRoute(path: '/my-jobs', builder: (_, __) => const JobsScreen(mine: true)),
              GoRoute(
                path: '/jobs/:id',
                builder: (ctx, state) => JobDetailScreen(jobId: int.parse(state.pathParameters['id']!)),
              ),
              GoRoute(path: '/processes', builder: (_, __) => const ProcessesScreen()),
              GoRoute(path: '/applications', builder: (_, __) => const ApplicationsScreen()),
              GoRoute(
                path: '/applications/:id',
                builder: (ctx, state) => ApplicationDetailScreen(
                  appId: int.parse(state.pathParameters['id']!),
                  initialScores: state.extra is Map ? Map<String, dynamic>.from(state.extra as Map) : null,
                ),
              ),
              GoRoute(path: '/evaluations', builder: (_, __) => const EvaluationsScreen()),
              GoRoute(path: '/interviews', builder: (_, __) => const InterviewsScreen()),
              GoRoute(path: '/committees', builder: (_, __) => const CommitteesScreen()),
              GoRoute(path: '/results', builder: (_, __) => const ResultsScreen()),
              GoRoute(path: '/offers', builder: (_, __) => const OffersScreen()),
              GoRoute(path: '/reports', builder: (_, __) => const ReportsScreen()),
              GoRoute(path: '/users', builder: (_, __) => const UsersScreen()),
              GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
            ],
          );

          return MaterialApp.router(
            title: 'HR Recruitment',
            theme: AppTheme.light,
            routerConfig: router,
          );
        },
      ),
    );
  }
}