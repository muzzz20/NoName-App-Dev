import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../services/dashboard_service.dart';
import 'dashboard_widgets.dart';

/// UC-22 Public Statistics Dashboard. Open to everyone (including
/// visitors). Shows aggregate impact only — NO PII (no names, no
/// individual donations/reports). Reads the same live aggregation as the
/// stakeholder dashboard, exposing only the safe top-line numbers.
class PublicStatsScreen extends StatefulWidget {
  const PublicStatsScreen({super.key});

  @override
  State<PublicStatsScreen> createState() => _PublicStatsScreenState();
}

class _PublicStatsScreenState extends State<PublicStatsScreen> {
  final _dashboard = DashboardService();
  late Future<DashboardStats> _statsF;

  @override
  void initState() {
    super.initState();
    _statsF = _dashboard.getStats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Our Impact'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async =>
            setState(() => _statsF = _dashboard.getStats()),
        child: ListView(
          padding: AppSpacing.pagePadding,
          children: [
            Text('Strayfriends @ UTM', style: AppText.displayLg),
            const SizedBox(height: AppSpacing.stackSm),
            Text(
              'Together, our community is making campus kinder for stray cats.',
              style: AppText.bodyBase.copyWith(color: AppColors.secondary),
            ),
            const SizedBox(height: AppSpacing.stackLg),
            FutureBuilder<DashboardStats>(
              future: _statsF,
              builder: (context, snap) {
                if (snap.hasError) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        const Icon(Icons.cloud_off_outlined,
                            size: 56, color: AppColors.outline),
                        const SizedBox(height: AppSpacing.stackMd),
                        Text("Couldn't load impact stats",
                            style: AppText.titleSm,
                            textAlign: TextAlign.center),
                        const SizedBox(height: AppSpacing.stackSm),
                        Text('Check your connection and try again.',
                            style: AppText.bodySm
                                .copyWith(color: AppColors.outline),
                            textAlign: TextAlign.center),
                        const SizedBox(height: AppSpacing.stackLg),
                        FilledButton(
                          onPressed: () => setState(
                              () => _statsF = _dashboard.getStats()),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                if (!snap.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(AppSpacing.stackXl),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final s = snap.data!;
                // Public-safe metrics only — aggregates, no PII.
                return KpiGrid(items: [
                  KpiItem('Cats reported', '${s.totalReports}', Icons.pets),
                  KpiItem('Funds raised',
                      'RM ${(s.totalFundsRaisedSen / 100).toStringAsFixed(2)}',
                      Icons.favorite),
                  KpiItem('Active campaigns', '${s.activeCampaigns}',
                      Icons.campaign),
                  KpiItem('Volunteer sign-ups', '${s.totalSignups}',
                      Icons.group),
                ]);
              },
            ),
            const SizedBox(height: AppSpacing.stackLg),
            Text(
              'Updated live. No personal information is shown on this page.',
              style: AppText.bodySm.copyWith(color: AppColors.secondary),
            ),
          ],
        ),
      ),
    );
  }
}
