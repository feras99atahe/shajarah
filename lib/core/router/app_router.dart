import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/onboarding/screens/splash_screen.dart';
import '../../features/onboarding/screens/welcome_screen.dart';
import '../../features/onboarding/screens/signup_screen.dart';
import '../../features/onboarding/screens/name_entry_screen.dart';
import '../../features/onboarding/screens/smart_link_screen.dart';
import '../../features/onboarding/screens/tree_reveal_screen.dart';
import '../../features/claims/screens/pending_claim_screen.dart';
import '../../features/tree/screens/tree_browse_screen.dart';
import '../../features/tree/screens/profile_screen.dart';
import '../../features/members/screens/members_screen.dart';
import '../../features/members/screens/add_member_screen.dart';
import '../../features/relationship/screens/relationship_finder_screen.dart';
import '../../features/admin/screens/account_screen.dart';
import '../../features/admin/screens/admin_login_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/admin/screens/admin_users_screen.dart';
import '../../features/admin/screens/import_screen.dart';
import '../../features/settings/screens/settings_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),
    GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
    GoRoute(path: '/login', builder: (_, __) => const SignupScreen(login: true)),
    GoRoute(path: '/name-entry', builder: (_, __) => const NameEntryScreen()),
    GoRoute(
      path: '/smart-link',
      builder: (_, state) => SmartLinkScreen(memberId: state.extra as String? ?? ''),
    ),
    GoRoute(path: '/tree-reveal', builder: (_, __) => const TreeRevealScreen()),
    GoRoute(path: '/pending', builder: (_, __) => const PendingClaimScreen()),
    GoRoute(path: '/tree', builder: (_, __) => const TreeBrowseScreen()),
    GoRoute(path: '/members', builder: (_, __) => const MembersScreen()),
    GoRoute(path: '/search', builder: (_, __) => const MembersScreen()),
    GoRoute(path: '/add-member', builder: (_, __) => const AddMemberScreen()),
    GoRoute(
      path: '/profile/:id',
      builder: (_, state) => ProfileScreen(memberId: state.pathParameters['id']!),
    ),
    GoRoute(path: '/relationship', builder: (_, __) => const RelationshipFinderScreen()),
    GoRoute(path: '/account', builder: (_, __) => const AccountScreen()),
    GoRoute(path: '/admin-login', builder: (_, __) => const AdminLoginScreen()),
    GoRoute(path: '/admin', builder: (_, __) => const AdminDashboardScreen()),
    GoRoute(path: '/admin/users', builder: (_, __) => const AdminUsersScreen()),
    GoRoute(path: '/import', builder: (_, __) => const ImportScreen()),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
  ],
  errorBuilder: (_, state) => Scaffold(
    body: Center(child: Text('Page not found: ${state.uri}')),
  ),
);
