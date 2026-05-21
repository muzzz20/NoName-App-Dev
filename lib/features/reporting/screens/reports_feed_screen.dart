import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../models/cat_report.dart';
import '../services/reports_service.dart';
import '../widgets/report_card.dart';

/// All Reports — the full public feed (UC-06), reached from Home's
/// "View all". Home shows only the 3 most recent; this lists every report.
class ReportsFeedScreen extends StatefulWidget {
  const ReportsFeedScreen({super.key});

  @override
  State<ReportsFeedScreen> createState() => _ReportsFeedScreenState();
}

class _ReportsFeedScreenState extends State<ReportsFeedScreen> {
  final _reportsService = ReportsService();
  late Stream<List<CatReport>> _reports = _reportsService.watchAllReports();

  Future<void> _refresh() async {
    setState(() => _reports = _reportsService.watchAllReports());
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Reports')),
      body: StreamBuilder<List<CatReport>>(
        stream: _reports,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: AppSpacing.pagePadding,
                child: Text(
                  'Could not load reports: ${snapshot.error}',
                  style: AppText.bodySm.copyWith(color: AppColors.outline),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final reports = snapshot.data ?? const <CatReport>[];
          if (reports.isEmpty) {
            return Center(
              child: Text(
                'No reports yet.',
                style: AppText.bodyBase.copyWith(color: AppColors.outline),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.stackLg),
              itemCount: reports.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.stackSm + 4),
              itemBuilder: (context, i) {
                final r = reports[i];
                return ReportCard(
                  report: r,
                  onTap: () =>
                      context.push('${AppRoutes.reportDetail}/${r.id}'),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
