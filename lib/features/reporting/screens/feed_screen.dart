import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../auth/models/user_profile.dart';
import '../../auth/services/auth_service.dart';
import '../models/cat_report.dart';
import '../services/reports_service.dart';
import '../widgets/report_card.dart';

/// Home (NAD-12 + Sprint 3 redesign) — UC-06 public feed.
///
/// Layout: header (greeting / sign-in) → role-aware quick-nav →
/// reports feed. Visitors can browse; auth-only actions prompt sign-in.
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _reportsService = ReportsService();
  final _authService = AuthService();

  late Stream<List<CatReport>> _reports = _reportsService.watchAllReports();
  UserProfile? _profile;

  bool get _isSignedIn => FirebaseAuth.instance.currentUser != null;
  bool get _isAdmin =>
      _profile?.role == 'admin' || _profile?.role == 'ngo';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (!_isSignedIn) return;
    final p = await _authService.loadProfile();
    if (!mounted) return;
    setState(() => _profile = p);
  }

  Future<void> _refresh() async {
    setState(() => _reports = _reportsService.watchAllReports());
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  void _requireSignIn(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sign in to $action.'),
        action: SnackBarAction(
          label: 'Sign In',
          onPressed: () => context.push(AppRoutes.login),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Strayfriends'),
        actions: [
          if (_isSignedIn)
            IconButton(
              tooltip: 'Profile',
              icon: const Icon(Icons.person_outline),
              onPressed: () => context.push(AppRoutes.profile),
            )
          else
            TextButton(
              onPressed: () => context.push(AppRoutes.login),
              child: const Text('Sign In'),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _isSignedIn
            ? context.push(AppRoutes.submitReport)
            : _requireSignIn('report a cat'),
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Report a Cat'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          _quickNav(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.stackLg, AppSpacing.stackSm, AppSpacing.stackLg, 0),
            child: Text('Recent Reports', style: AppText.titleSm),
          ),
          Expanded(child: _feed()),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(AppSpacing.stackLg,
          AppSpacing.stackMd, AppSpacing.stackLg, AppSpacing.stackMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isSignedIn
                ? 'Hi, ${_profile?.fullName ?? 'friend'} 👋'
                : 'Welcome to Strayfriends',
            style: AppText.titleSm,
          ),
          const SizedBox(height: 2),
          Text(
            _isSignedIn
                ? 'Thanks for helping UTM\'s stray cats.'
                : 'Help stray cats at UTM — browse, donate, volunteer.',
            style: AppText.bodySm.copyWith(color: AppColors.secondary),
          ),
        ],
      ),
    );
  }

  Widget _quickNav() {
    final items = <_NavItem>[
      _NavItem('Campaigns', Icons.campaign, () => context.push(AppRoutes.campaigns)),
      _NavItem('Volunteer', Icons.volunteer_activism,
          () => context.push(AppRoutes.activities)),
      _NavItem('Our Impact', Icons.insights,
          () => context.push(AppRoutes.publicStats)),
      if (_isSignedIn) ...[
        _NavItem('My Reports', Icons.history,
            () => context.push(AppRoutes.myReports)),
        _NavItem('My Donations', Icons.receipt_long,
            () => context.push(AppRoutes.myDonations)),
        _NavItem('My Activities', Icons.event_available,
            () => context.push(AppRoutes.myActivities)),
      ],
      if (_isAdmin) ...[
        _NavItem('Dashboard', Icons.dashboard,
            () => context.push(AppRoutes.dashboard)),
        _NavItem('New Campaign', Icons.add_business,
            () => context.push(AppRoutes.adminCampaign)),
        _NavItem('New Activity', Icons.add_task,
            () => context.push(AppRoutes.adminActivity)),
      ],
    ];

    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.stackLg),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.stackMd),
        itemBuilder: (context, i) => _NavTile(item: items[i]),
      ),
    );
  }

  Widget _feed() {
    return StreamBuilder<List<CatReport>>(
      stream: _reports,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _FeedMessage(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load reports',
            subtitle: snapshot.error.toString(),
            onRetry: () => setState(
                () => _reports = _reportsService.watchAllReports()),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }
        final reports = snapshot.data ?? const [];
        if (reports.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [SizedBox(height: 80), _EmptyState()],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.separated(
            padding: AppSpacing.pagePadding,
            itemCount: reports.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: AppSpacing.stackSm + 4),
            itemBuilder: (context, i) {
              final r = reports[i];
              return ReportCard(
                report: r,
                onTap: () => context.push('${AppRoutes.reportDetail}/${r.id}'),
              );
            },
          ),
        );
      },
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  _NavItem(this.label, this.icon, this.onTap);
}

class _NavTile extends StatelessWidget {
  final _NavItem item;
  const _NavTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        width: 84,
        padding: const EdgeInsets.all(AppSpacing.stackSm),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, color: AppColors.primary, size: 26),
            const SizedBox(height: 6),
            Text(
              item.label,
              style: AppText.bodySm,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.pagePadding,
      child: Column(
        children: [
          const Icon(Icons.pets_outlined, size: 64, color: AppColors.outline),
          const SizedBox(height: AppSpacing.stackLg),
          Text('No reports yet',
              style: AppText.titleSm, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.stackSm),
          Text('Be the first to report a stray cat on campus.',
              style: AppText.bodySm.copyWith(color: AppColors.outline),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _FeedMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onRetry;
  const _FeedMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.pagePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.outline, size: 48),
            const SizedBox(height: AppSpacing.stackMd),
            Text(title, style: AppText.titleSm, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.stackSm),
            Text(subtitle,
                style: AppText.bodySm.copyWith(color: AppColors.outline),
                textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.stackLg),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
