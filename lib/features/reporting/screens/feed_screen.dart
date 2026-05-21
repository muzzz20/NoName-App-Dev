import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../auth/models/user_profile.dart';
import '../../auth/services/auth_service.dart';
import '../../dashboard/services/dashboard_service.dart';
import '../../fundraising/models/campaign.dart';
import '../../fundraising/services/campaigns_service.dart';
import '../models/cat_report.dart';
import '../services/reports_service.dart';
import '../widgets/report_card.dart';

/// Home — impact-first design (Sprint 3 rework). UC-06 public feed.
///
/// Layout: mission hero → live impact stats → primary CTAs (Report /
/// Donate / Volunteer) → featured campaign → role-aware quick links →
/// recent reports. Visitors can browse everything read-only; auth-only
/// actions prompt sign-in.
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _reportsService = ReportsService();
  final _authService = AuthService();
  final _dashboard = DashboardService();
  final _campaigns = CampaignsService();

  late Stream<List<CatReport>> _reports = _reportsService.watchAllReports();
  late Future<DashboardStats> _statsF = _dashboard.getStats();
  UserProfile? _profile;

  bool get _isSignedIn => FirebaseAuth.instance.currentUser != null;
  bool get _isAdmin => _profile?.role == 'admin' || _profile?.role == 'ngo';

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
    setState(() {
      _reports = _reportsService.watchAllReports();
      _statsF = _dashboard.getStats();
    });
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  void _requireSignIn(String action) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Sign in to $action.'),
      action: SnackBarAction(
        label: 'Sign In',
        onPressed: () => context.push(AppRoutes.login),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Strayfriends'),
        actions: [
          IconButton(
            tooltip: 'Help',
            icon: const Icon(Icons.help_outline),
            onPressed: () => context.push(AppRoutes.help),
          ),
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
      body: StreamBuilder<List<CatReport>>(
        stream: _reports,
        builder: (context, snapshot) {
          final reports = snapshot.data ?? const <CatReport>[];
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _hero(),
                _statsStrip(),
                const SizedBox(height: AppSpacing.stackLg),
                _ctaRow(),
                const SizedBox(height: AppSpacing.stackLg),
                _featuredCampaign(),
                if (_isSignedIn) _quickLinks(),
                _reportsHeader(),
                ..._reportsBody(snapshot, reports),
                const SizedBox(height: 96),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Hero ────────────────────────────────────────────────────────────
  Widget _hero() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(AppSpacing.stackLg,
          AppSpacing.stackMd, AppSpacing.stackLg, AppSpacing.stackMd),
      padding: const EdgeInsets.all(AppSpacing.stackLg),
      decoration: BoxDecoration(
        // Warm maroon gradient (plum → maroon → deep maroon) for depth.
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7A1228), Color(0xFF570000), Color(0xFF3A0000)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF570000).withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Strayfriends @ UTM',
              style: AppText.bodySm.copyWith(color: AppColors.onPrimaryContainer)),
          const SizedBox(height: 6),
          Text(
            _isSignedIn
                ? 'Welcome back,\n${_profile?.fullName ?? 'friend'}.'
                : 'Every cat deserves\ncare at UTM.',
            style: AppText.displayLg.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            'Report sightings, fund care, and volunteer — together.',
            style: AppText.bodySm.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  // ── Live impact stats ───────────────────────────────────────────────
  Widget _statsStrip() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.stackLg),
      child: FutureBuilder<DashboardStats>(
        future: _statsF,
        builder: (context, snap) {
          final s = snap.data;
          return Row(
            children: [
              _statCard('Cats reported',
                  s == null ? '—' : '${s.totalReports}', Icons.pets),
              const SizedBox(width: AppSpacing.stackSm),
              _statCard(
                  'Raised',
                  s == null
                      ? '—'
                      : 'RM ${(s.totalFundsRaisedSen / 100).toStringAsFixed(0)}',
                  Icons.favorite),
              const SizedBox(width: AppSpacing.stackSm),
              _statCard('Volunteers',
                  s == null ? '—' : '${s.totalSignups}', Icons.group),
            ],
          );
        },
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.stackMd, horizontal: AppSpacing.stackSm),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(height: 6),
            Text(value,
                style: AppText.titleSm.copyWith(color: AppColors.primary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(label,
                style: AppText.bodySm.copyWith(color: AppColors.secondary),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  // ── Primary CTAs ────────────────────────────────────────────────────
  Widget _ctaRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.stackLg),
      child: Row(
        children: [
          _ctaCard('Report', Icons.add_a_photo,
              const [Color(0xFF8B0000), Color(0xFF5A0000)], () {
            _isSignedIn
                ? context.push(AppRoutes.submitReport)
                : _requireSignIn('report a cat');
          }),
          const SizedBox(width: AppSpacing.stackSm),
          _ctaCard('Donate', Icons.volunteer_activism,
              const [Color(0xFFA8203A), Color(0xFF6E1020)],
              () => context.push(AppRoutes.campaigns)),
          const SizedBox(width: AppSpacing.stackSm),
          _ctaCard('Volunteer', Icons.diversity_3,
              const [Color(0xFFB5482F), Color(0xFF7A2A18)],
              () => context.push(AppRoutes.activities)),
        ],
      ),
    );
  }

  Widget _ctaCard(
      String label, IconData icon, List<Color> gradient, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.stackMd),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: [
              BoxShadow(
                color: gradient.first.withValues(alpha: 0.30),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(height: 6),
              Text(label,
                  style: AppText.bodyBase.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Featured campaign ───────────────────────────────────────────────
  Widget _featuredCampaign() {
    return StreamBuilder<List<Campaign>>(
      stream: _campaigns.watchActiveCampaigns(limit: 1),
      builder: (context, snap) {
        final list = snap.data ?? const <Campaign>[];
        if (list.isEmpty) return const SizedBox.shrink();
        final c = list.first;
        return Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.stackLg, 0,
              AppSpacing.stackLg, AppSpacing.stackLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('★ Featured campaign', style: AppText.titleSm),
              const SizedBox(height: AppSpacing.stackSm),
              InkWell(
                onTap: () => context.push('/campaign/${c.id}'),
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AspectRatio(
                        aspectRatio: 16 / 7,
                        child: Image.network(
                          c.imageUrl ?? '',
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: AppColors.surfaceVariant,
                            child: const Icon(Icons.pets,
                                size: 36, color: AppColors.outline),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.stackMd),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.title,
                                style: AppText.bodyBase
                                    .copyWith(fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: AppSpacing.stackSm),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: c.progress,
                                minHeight: 8,
                                backgroundColor: AppColors.surfaceVariant,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'RM ${(c.currentAmountSen / 100).toStringAsFixed(0)} raised of RM ${(c.goalAmountSen / 100).toStringAsFixed(0)}',
                              style: AppText.bodySm
                                  .copyWith(color: AppColors.secondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Role-aware quick links (signed-in) ──────────────────────────────
  Widget _quickLinks() {
    final items = <_NavItem>[
      _NavItem('My Reports', Icons.history, () => context.push(AppRoutes.myReports)),
      _NavItem('My Donations', Icons.receipt_long,
          () => context.push(AppRoutes.myDonations)),
      _NavItem('My Activities', Icons.event_available,
          () => context.push(AppRoutes.myActivities)),
      if (_isAdmin) ...[
        _NavItem('Dashboard', Icons.dashboard,
            () => context.push(AppRoutes.dashboard)),
        _NavItem('New Campaign', Icons.add_business,
            () => context.push(AppRoutes.adminCampaign)),
        _NavItem('New Activity', Icons.add_task,
            () => context.push(AppRoutes.adminActivity)),
      ],
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.stackLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(
                AppSpacing.stackLg, 0, AppSpacing.stackLg, AppSpacing.stackSm),
            child: _QuickLinksLabel(),
          ),
          SizedBox(
            height: 88,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.stackLg),
              itemCount: items.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: AppSpacing.stackSm),
              itemBuilder: (context, i) => _NavTile(item: items[i]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Reports ─────────────────────────────────────────────────────────
  Widget _reportsHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.stackLg, 0, AppSpacing.stackLg, AppSpacing.stackSm),
      child: _SectionLabel('Recent Reports'),
    );
  }

  List<Widget> _reportsBody(
      AsyncSnapshot<List<CatReport>> snapshot, List<CatReport> reports) {
    if (snapshot.hasError) {
      return [
        Padding(
          padding: AppSpacing.pagePadding,
          child: Text('Could not load reports: ${snapshot.error}',
              style: AppText.bodySm.copyWith(color: AppColors.outline)),
        ),
      ];
    }
    if (snapshot.connectionState == ConnectionState.waiting &&
        !snapshot.hasData) {
      return const [
        Padding(
          padding: EdgeInsets.all(AppSpacing.stackXl),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (reports.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: _EmptyState(),
        ),
      ];
    }
    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.stackLg),
        child: Column(
          children: [
            for (final r in reports) ...[
              ReportCard(
                report: r,
                onTap: () => context.push('${AppRoutes.reportDetail}/${r.id}'),
              ),
              const SizedBox(height: AppSpacing.stackSm + 4),
            ],
          ],
        ),
      ),
    ];
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
        width: 96,
        padding: const EdgeInsets.all(AppSpacing.stackSm),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, color: AppColors.primary, size: 24),
            const SizedBox(height: 6),
            Text(item.label,
                style: AppText.bodySm,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) =>
      Align(alignment: Alignment.centerLeft, child: Text(text, style: AppText.titleSm));
}

class _QuickLinksLabel extends StatelessWidget {
  const _QuickLinksLabel();
  @override
  Widget build(BuildContext context) =>
      Align(alignment: Alignment.centerLeft, child: Text('Quick links', style: AppText.titleSm));
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
