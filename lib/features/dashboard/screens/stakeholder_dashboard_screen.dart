import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../fundraising/models/campaign.dart';
import '../../fundraising/services/campaigns_service.dart';
import '../../reporting/models/cat_report.dart';
import '../../reporting/services/reports_service.dart';
import '../services/dashboard_service.dart';
import 'dashboard_widgets.dart';

/// UC-21 Stakeholder Dashboard (admin/NGO). KPI cards + 30-day donation
/// trend + recent campaigns + recent reports.
class StakeholderDashboardScreen extends StatefulWidget {
  const StakeholderDashboardScreen({super.key});

  @override
  State<StakeholderDashboardScreen> createState() =>
      _StakeholderDashboardScreenState();
}

class _StakeholderDashboardScreenState
    extends State<StakeholderDashboardScreen> {
  final _dashboard = DashboardService();
  final _campaigns = CampaignsService();
  final _reports = ReportsService();

  late Future<DashboardStats> _statsF;
  late Future<List<DailyDonation>> _trendF;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    _statsF = _dashboard.getStats();
    _trendF = _dashboard.getDonationTrend();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(_refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(_refresh),
        child: ListView(
          padding: AppSpacing.pagePadding,
          children: [
            FutureBuilder<DashboardStats>(
              future: _statsF,
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(AppSpacing.stackXl),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final s = snap.data!;
                return KpiGrid(items: [
                  KpiItem('Reports', '${s.totalReports}', Icons.pets),
                  KpiItem('Funds raised',
                      'RM ${(s.totalFundsRaisedSen / 100).toStringAsFixed(2)}',
                      Icons.volunteer_activism),
                  KpiItem('Active campaigns', '${s.activeCampaigns}',
                      Icons.campaign),
                  KpiItem('Donations', '${s.totalDonations}', Icons.payments),
                  KpiItem('Activities', '${s.totalActivities}', Icons.event),
                  KpiItem('Volunteer sign-ups', '${s.totalSignups}',
                      Icons.group),
                ]);
              },
            ),
            const SizedBox(height: AppSpacing.stackLg),
            Text('Donations — last 30 days', style: AppText.titleSm),
            const SizedBox(height: AppSpacing.stackMd),
            FutureBuilder<List<DailyDonation>>(
              future: _trendF,
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const SizedBox(
                      height: 120,
                      child: Center(child: CircularProgressIndicator()));
                }
                return DonationSparkline(data: snap.data!);
              },
            ),
            const SizedBox(height: AppSpacing.stackLg),
            Text('Active campaigns', style: AppText.titleSm),
            const SizedBox(height: AppSpacing.stackMd),
            StreamBuilder<List<Campaign>>(
              stream: _campaigns.watchActiveCampaigns(limit: 5),
              builder: (context, snap) {
                final campaigns = snap.data ?? [];
                if (campaigns.isEmpty) {
                  return _muted('No active campaigns.');
                }
                return Column(
                  children: campaigns
                      .map((c) => ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.campaign_outlined),
                            title: Text(c.title,
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text(
                                'RM ${(c.currentAmountSen / 100).toStringAsFixed(2)} / RM ${(c.goalAmountSen / 100).toStringAsFixed(2)}'),
                            onTap: () => context.push('/campaign/${c.id}'),
                          ))
                      .toList(),
                );
              },
            ),
            const SizedBox(height: AppSpacing.stackLg),
            Text('Recent reports', style: AppText.titleSm),
            const SizedBox(height: AppSpacing.stackMd),
            StreamBuilder<List<CatReport>>(
              stream: _reports.watchAllReports(limit: 5),
              builder: (context, snap) {
                final reports = snap.data ?? [];
                if (reports.isEmpty) return _muted('No reports yet.');
                return Column(
                  children: reports
                      .map((r) => ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.pets_outlined),
                            title: Text(r.condition.label),
                            subtitle: Text(
                                r.locationLabel ?? r.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            onTap: () => context.push('/report/${r.id}'),
                          ))
                      .toList(),
                );
              },
            ),
            const SizedBox(height: AppSpacing.stackXl),
          ],
        ),
      ),
    );
  }

  Widget _muted(String text) => Text(text,
      style: AppText.bodyBase.copyWith(color: AppColors.secondary));
}
