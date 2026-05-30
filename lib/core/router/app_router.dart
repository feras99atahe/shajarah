import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/admin_login_screen.dart';
import '../../features/auth/screens/otp_screen.dart';
import '../../features/auth/screens/phone_login_screen.dart';
import '../../features/auth/screens/profile_setup_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/relationship/screens/relationship_finder_screen.dart';
import '../../features/search/screens/search_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/tree/screens/add_member_screen.dart';
import '../../features/tree/screens/member_detail_screen.dart';
import '../../features/tree/screens/members_list_screen.dart';
import '../../features/tree/screens/tree_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (_, __) => const PhoneLoginScreen(),
    ),
    GoRoute(
      path: '/otp',
      builder: (context, state) {
        final phone = state.extra as String? ?? '';
        return OtpScreen(phone: phone);
      },
    ),
    GoRoute(
      path: '/admin-login',
      builder: (_, __) => const AdminLoginScreen(),
    ),
    GoRoute(
      path: '/profile-setup',
      builder: (_, __) => const ProfileSetupScreen(),
    ),
    GoRoute(
      path: '/tree',
      builder: (_, __) => const TreeScreen(),
    ),
    GoRoute(
      path: '/add-member',
      builder: (context, state) {
        final parentId = state.extra as String?;
        return AddMemberScreen(parentId: parentId);
      },
    ),
    GoRoute(
      path: '/member/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return MemberDetailScreen(memberId: id);
      },
    ),
    GoRoute(
      path: '/members',
      builder: (_, __) => const MembersListScreen(),
    ),
    GoRoute(
      path: '/search',
      builder: (_, __) => const SearchScreen(),
    ),
    GoRoute(
      path: '/relationship',
      builder: (_, __) => const RelationshipFinderScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (_, __) => const SettingsScreen(),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text('Page not found: ${state.uri}'),
    ),
  ),
);
