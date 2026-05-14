import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/profile_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/reporting/screens/feed_screen.dart';
import '../../features/reporting/screens/report_success_screen.dart';
import '../../features/reporting/screens/submit_report_screen.dart';

class AppRoutes {
  AppRoutes._();
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const profile = '/profile';
  static const submitReport = '/report/new';
  static const reportSuccess = '/report/success';
  static const reportDetail = '/report'; // /report/:id
  static const myReports = '/my-reports';
}

/// Router with FirebaseAuth-driven redirect guard.
///
/// - Unauthenticated users at any protected route → `/login`.
/// - Authenticated users at `/login` or `/register` → `/home`.
/// - `/` (splash) shown only until Firebase auth state is known.
GoRouter buildAppRouter() {
  final authStream = FirebaseAuth.instance.authStateChanges();
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: GoRouterRefreshStream(authStream),
    redirect: (context, state) {
      final isSignedIn = FirebaseAuth.instance.currentUser != null;
      final location = state.matchedLocation;
      final atAuthScreen = location == AppRoutes.login ||
          location == AppRoutes.register;
      final atSplash = location == AppRoutes.splash;

      if (atSplash) {
        return isSignedIn ? AppRoutes.home : AppRoutes.login;
      }
      if (!isSignedIn && !atAuthScreen) {
        return AppRoutes.login;
      }
      if (isSignedIn && atAuthScreen) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, _) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, _) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (_, _) => const FeedScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (_, _) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.submitReport,
        builder: (_, _) => const SubmitReportScreen(),
      ),
      GoRoute(
        path: AppRoutes.reportSuccess,
        builder: (_, state) => ReportSuccessScreen(
          reportId: state.uri.queryParameters['id'],
        ),
      ),
    ],
  );
}

/// Bridges a [Stream] to GoRouter's refresh mechanism, so route guards
/// re-run whenever auth state changes.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (_) => notifyListeners(),
        );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
