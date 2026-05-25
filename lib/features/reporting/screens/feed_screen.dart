import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/sign_in_prompt.dart';
import '../../auth/models/user_profile.dart';
import '../../auth/services/auth_service.dart';
import '../../dashboard/services/dashboard_service.dart';
import '../../fundraising/models/campaign.dart';
import '../../fundraising/services/campaigns_service.dart';
import '../models/cat_report.dart';
import '../services/reports_service.dart';
import '../widgets/report_card.dart';

/// Formats [n] with comma thousands separators (no `intl` dependency).
String _thousands(int n) {
  final digits = n.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  return n < 0 ? '-$buf' : buf.toString();
}

/// Whole-ringgit label from a sen amount, e.g. 150000 → 'RM 1,500'.
String _rmWhole(int sen) => 'RM ${_thousands(sen ~/ 100)}';

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

  StreamSubscription<User?>? _authSub;

  @override
  void initState() {
    super.initState();
    // React to auth changes (register / login / logout) so the appbar,
    // hero greeting and quick-links update live — this screen is the
    // persistent root, so it must not rely on a one-shot read. The stream
    // also emits the current state immediately on subscribe, covering the
    // initial build.
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted) return;
      setState(() => _profile = null);
      if (user != null) _loadProfile();
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
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

  void _requireSignIn(String action) => showSignInPrompt(context, action);

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
                _publicStatsLink(),
                const SizedBox(height: AppSpacing.stackMd),
                _ctaRow(),
                const SizedBox(height: AppSpacing.stackXl),
                _featuredCampaign(),
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
          Text(
            _isSignedIn
                ? 'Welcome back,\n${_profile?.fullName ?? 'friend'}.'
                : 'Every cat deserves\ncare at UTM.',
            style: AppText.displayLg.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            'Report sightings, fund care, and volunteer together.',
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

  // ── Public-stats entry (visitor path to the "Our Impact" page) ──────
  Widget _publicStatsLink() {
    return Center(
      child: TextButton(
        onPressed: () => context.push(AppRoutes.publicStats),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('See our full impact',
                style: AppText.bodySm.copyWith(
                    fontWeight: FontWeight.w600, color: AppColors.primary)),
            const Icon(Icons.chevron_right,
                size: 18, color: AppColors.primary),
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
              // Browsing activities is public; signing up is gated on the
              // activity detail screen.
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

  // ── Shared section header (accent bar + title + "View all") ─────────
  // Gives each feed section a clear visual start without a full-width
  // divider line (the divider approach was reverted in 3995076).
  Widget _sectionHeaderRow(String title, VoidCallback onViewAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 4,
              height: 22,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
            const SizedBox(width: AppSpacing.stackSm),
            Text(title,
                style: AppText.titleSm.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
        InkWell(
          onTap: onViewAll,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Text('View all',
                    style: AppText.bodySm.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary)),
                const Icon(Icons.chevron_right,
                    size: 18, color: AppColors.primary),
              ],
            ),
          ),
        ),
      ],
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
        final pct = (c.progress * 100).round();
        final daysLeft = c.endsAt?.difference(DateTime.now()).inDays;
        return Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.stackLg, 0,
              AppSpacing.stackLg, AppSpacing.stackXl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeaderRow(
                  'Featured campaign', () => context.push(AppRoutes.campaigns)),
              const SizedBox(height: AppSpacing.stackSm),
              InkWell(
                onTap: () => context.push('/campaign/${c.id}'),
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Container(
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
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
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
                          Positioned(
                            top: AppSpacing.stackSm,
                            left: AppSpacing.stackSm,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text('FEATURED',
                                  style: AppText.labelCaps.copyWith(
                                      color: Colors.white, fontSize: 10)),
                            ),
                          ),
                        ],
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
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: LinearProgressIndicator(
                                      value: c.progress,
                                      minHeight: 10,
                                      backgroundColor:
                                          AppColors.surfaceVariant,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.stackSm),
                                Text('$pct% funded',
                                    style: AppText.bodySm.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text(_rmWhole(c.currentAmountSen),
                                    style: AppText.bodyBase.copyWith(
                                        fontWeight: FontWeight.w700)),
                                Text(' raised',
                                    style: AppText.bodySm.copyWith(
                                        color: AppColors.secondary)),
                                Text('  ·  of ${_rmWhole(c.goalAmountSen)} goal',
                                    style: AppText.bodySm.copyWith(
                                        color: AppColors.secondary)),
                              ],
                            ),
                            if (daysLeft != null && daysLeft >= 0) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.schedule,
                                      size: 13, color: AppColors.outline),
                                  const SizedBox(width: 4),
                                  Text(
                                      daysLeft == 0
                                          ? 'Ends today'
                                          : '$daysLeft day(s) left',
                                      style: AppText.labelCaps.copyWith(
                                          color: AppColors.outline)),
                                ],
                              ),
                            ],
                            const SizedBox(height: AppSpacing.stackMd),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                icon: const Icon(Icons.volunteer_activism,
                                    size: 18),
                                label: const Text('Donate now'),
                                onPressed: () => _isSignedIn
                                    ? context.push(
                                        '${AppRoutes.donate}/${c.id}')
                                    : _requireSignIn('donate'),
                              ),
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

  // ── Reports ─────────────────────────────────────────────────────────
  Widget _reportsHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.stackLg, 0, AppSpacing.stackLg, AppSpacing.stackSm),
      child: _sectionHeaderRow(
          'Recent Reports', () => context.push(AppRoutes.reports)),
    );
  }

  List<Widget> _reportsBody(
      AsyncSnapshot<List<CatReport>> snapshot, List<CatReport> reports) {
    if (snapshot.hasError) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: _FeedNotice(
            icon: Icons.cloud_off_outlined,
            title: "Couldn't load reports",
            message: 'Check your connection and try again.',
            actionLabel: 'Retry',
            onAction: _refresh,
          ),
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
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: _FeedNotice(
            icon: Icons.pets_outlined,
            title: 'No reports yet',
            message: _isSignedIn
                ? 'Be the first to report a stray cat on campus.'
                : 'Sign in to be the first to report a stray cat on campus.',
            actionLabel: _isSignedIn ? 'Report a cat' : 'Sign In',
            onAction: () => _isSignedIn
                ? context.push(AppRoutes.submitReport)
                : _requireSignIn('report a cat'),
          ),
        ),
      ];
    }
    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.stackLg),
        child: Column(
          children: [
            for (final r in reports.take(3)) ...[
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


/// Shared placeholder for the reports section — used for both the empty
/// state and load errors, with an optional call-to-action button.
class _FeedNotice extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  const _FeedNotice({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.pagePadding,
      child: Column(
        children: [
          Icon(icon, size: 56, color: AppColors.outline),
          const SizedBox(height: AppSpacing.stackMd),
          Text(title, style: AppText.titleSm, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.stackSm),
          Text(message,
              style: AppText.bodySm.copyWith(color: AppColors.outline),
              textAlign: TextAlign.center),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.stackLg),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
