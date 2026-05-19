import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/profile_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/reporting/screens/feed_screen.dart';
import '../../features/reporting/screens/my_reports_screen.dart';
import '../../features/reporting/screens/report_detail_screen.dart';
import '../../features/reporting/screens/report_success_screen.dart';
import '../../features/reporting/screens/submit_report_screen.dart';

import '../../features/fundraising/screens/admin_manage_campaign_screen.dart';
import '../../features/fundraising/screens/campaign_detail_screen.dart';
import '../../features/fundraising/screens/campaigns_list_screen.dart';
import '../../features/fundraising/screens/donation_flow_screen.dart';
import '../../features/fundraising/screens/my_donations_screen.dart';
import '../../features/fundraising/screens/receipt_screen.dart';

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
  
  // Fundraising routes
  static const campaigns = '/campaigns';
  static const campaignDetail = '/campaign'; // /campaign/:id
  static const donate = '/donate'; // /donate/:id
  static const myDonations = '/my-donations';
  static const receipt = '/receipt';
  static const adminCampaign = '/admin-campaign';
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
      GoRoute(
        path: '${AppRoutes.reportDetail}/:id',
        builder: (_, state) =>
            ReportDetailScreen(reportId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.myReports,
        builder: (_, _) => const MyReportsScreen(),
      ),
      GoRoute(
        path: AppRoutes.campaigns,
        builder: (_, _) => const CampaignsListScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.campaignDetail}/:id',
        builder: (_, state) => CampaignDetailScreen(
          campaignId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '${AppRoutes.donate}/:id',
        builder: (_, state) => DonationFlowScreen(
          campaignId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.myDonations,
        builder: (_, _) => const MyDonationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.receipt,
        builder: (_, state) {
          final args = state.extra as Map<String, dynamic>? ?? {};
          return ReceiptScreen(
            campaignName: args['campaignName'] ?? '',
            amount: args['amount'] ?? 0.0,
            transactionId: args['transactionId'] ?? '',
            date: args['date'] ?? DateTime.now(),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.adminCampaign,
        builder: (_, _) => const AdminManageCampaignScreen(),
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
