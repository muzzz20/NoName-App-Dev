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
import '../../features/reporting/screens/reports_feed_screen.dart';
import '../../features/reporting/screens/report_success_screen.dart';
import '../../features/reporting/screens/submit_report_screen.dart';

import '../../features/fundraising/screens/admin_manage_campaign_screen.dart';
import '../../features/fundraising/screens/campaign_detail_screen.dart';
import '../../features/fundraising/screens/campaigns_list_screen.dart';
import '../../features/fundraising/screens/donation_flow_screen.dart';
import '../../features/fundraising/screens/my_donations_screen.dart';
import '../../features/fundraising/screens/receipt_screen.dart';

import '../../features/volunteer/screens/activities_list_screen.dart';
import '../../features/volunteer/screens/activity_detail_screen.dart';
import '../../features/volunteer/screens/my_activities_screen.dart';
import '../../features/volunteer/screens/admin_manage_activity_screen.dart';

import '../../features/dashboard/screens/stakeholder_dashboard_screen.dart';
import '../../features/dashboard/screens/public_stats_screen.dart';

import '../../features/help/screens/help_screen.dart';

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
  static const reports = '/reports'; // full public feed
  static const myReports = '/my-reports';
  
  // Fundraising routes
  static const campaigns = '/campaigns';
  static const campaignDetail = '/campaign'; // /campaign/:id
  static const donate = '/donate'; // /donate/:id
  static const myDonations = '/my-donations';
  static const receipt = '/receipt';
  static const adminCampaign = '/admin-campaign';

  // Volunteer routes (Sprint 3)
  static const activities = '/activities';
  static const activityDetail = '/activity'; // /activity/:id
  static const myActivities = '/my-activities';
  static const adminActivity = '/admin-activity';

  // Dashboard routes (Sprint 3)
  static const dashboard = '/dashboard';
  static const publicStats = '/public-stats';

  // Help (Sprint 4)
  static const help = '/help';
}

/// Routes a visitor (not signed in) may view without logging in. These
/// mirror the SRDD's Visitor actor: public feed (UC-06), report detail
/// (UC-07), browse campaigns + campaign detail (UC-09/10), browse
/// activities + activity detail (UC-16/17), and public stats (UC-22).
/// Auth-only actions on those screens (donate, sign up, report) prompt
/// sign-in. Everything else (profile, submit, my-*, admin-*, receipt)
/// stays gated.
bool _isPublicRoute(String location) {
  if (location == AppRoutes.home) return true;
  if (location == AppRoutes.reports) return true;
  if (location == AppRoutes.campaigns) return true;
  if (location.startsWith('${AppRoutes.campaignDetail}/')) return true;
  if (location == AppRoutes.activities) return true;
  if (location.startsWith('${AppRoutes.activityDetail}/')) return true;
  if (location == AppRoutes.publicStats) return true;
  if (location == AppRoutes.help) return true;
  // Report detail is public, but /report/new + /report/success are not.
  if (location.startsWith('${AppRoutes.reportDetail}/') &&
      location != AppRoutes.submitReport &&
      location != AppRoutes.reportSuccess) {
    return true;
  }
  return false;
}

/// Router with FirebaseAuth-driven redirect guard.
///
/// - Visitors may view public routes (see [_isPublicRoute]); other
///   protected routes → `/login`.
/// - Authenticated users at `/login` or `/register` → `/home`.
/// - `/` (splash) always resolves to the public `/home` feed.
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

      // Everyone (incl. visitors) lands on the public home feed.
      if (atSplash) {
        return AppRoutes.home;
      }
      // Signed-in users skip the auth screens.
      if (isSignedIn && atAuthScreen) {
        return AppRoutes.home;
      }
      // Visitors may view public routes; anything else → login.
      if (!isSignedIn && !atAuthScreen && !_isPublicRoute(location)) {
        return AppRoutes.login;
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
        path: AppRoutes.reports,
        builder: (_, _) => const ReportsFeedScreen(),
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
        builder: (_, state) => ReceiptScreen(
          sessionId: state.uri.queryParameters['session_id'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.adminCampaign,
        builder: (_, _) => const AdminManageCampaignScreen(),
      ),

      // Volunteer (Sprint 3)
      GoRoute(
        path: AppRoutes.activities,
        builder: (_, _) => ActivitiesListScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.activityDetail}/:id',
        builder: (_, state) => ActivityDetailScreen(
          activityId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.myActivities,
        builder: (_, _) => MyActivitiesScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminActivity,
        builder: (_, _) => AdminManageActivityScreen(),
      ),

      // Dashboards (Sprint 3)
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (_, _) => const StakeholderDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.publicStats,
        builder: (_, _) => const PublicStatsScreen(),
      ),
      GoRoute(
        path: AppRoutes.help,
        builder: (_, _) => const HelpScreen(),
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
