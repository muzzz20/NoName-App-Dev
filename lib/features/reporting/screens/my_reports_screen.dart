import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../models/cat_report.dart';
import '../services/reports_service.dart';
import '../widgets/report_card.dart';

/// My Reports (NAD-14) — UC-08. Mirrors Feed but filtered to current user
/// + shows status pill on every card.
class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  final _reportsService = ReportsService();
  late Stream<List<CatReport>> _reports;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    _reports = uid == null
        ? const Stream.empty()
        : _reportsService.watchUserReports(userId: uid);
  }

  Future<void> _refresh() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    setState(() {
      _reports = uid == null
          ? const Stream.empty()
          : _reportsService.watchUserReports(userId: uid);
    });
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reports'),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.home),
        ),
      ),
      body: StreamBuilder<List<CatReport>>(
        stream: _reports,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: AppSpacing.pagePadding,
                child: Text(
                  'Could not load your reports.\n${snapshot.error}',
                  style: AppText.bodySm.copyWith(color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          final reports = snapshot.data ?? const [];
          if (reports.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [SizedBox(height: 120), _MyEmpty()],
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
                  showStatusBadge: true,
                  onTap: () =>
                      context.go('${AppRoutes.reportDetail}/${r.id}'),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _MyEmpty extends StatelessWidget {
  const _MyEmpty();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.pagePadding,
      child: Column(
        children: [
          const Icon(
            Icons.history,
            size: 64,
            color: AppColors.outline,
          ),
          const SizedBox(height: AppSpacing.stackLg),
          Text(
            "You haven't submitted any reports yet",
            style: AppText.titleSm,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.stackSm),
          Text(
            'Spot a stray cat? Submit a report and help volunteers find them.',
            style: AppText.bodySm.copyWith(color: AppColors.outline),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.stackLg),
          ElevatedButton.icon(
            onPressed: () => context.go(AppRoutes.submitReport),
            icon: const Icon(Icons.add_a_photo_outlined),
            label: const Text('Submit Report'),
          ),
        ],
      ),
    );
  }
}
