import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../models/cat_report.dart';
import '../services/reports_service.dart';
import '../widgets/report_card.dart';

/// Reports Feed (NAD-12) — UC-06. Replaces HomePlaceholderScreen at /home.
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _reportsService = ReportsService();

  // Backing stream — re-assigned by pull-to-refresh.
  late Stream<List<CatReport>> _reports =
      _reportsService.watchAllReports();

  Future<void> _refresh() async {
    // For Firestore streams, the live subscription always provides the
    // latest data. Re-assigning the stream just gives users feedback that
    // the gesture was received and forces an immediate re-listen.
    setState(() {
      _reports = _reportsService.watchAllReports();
    });
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports Feed'),
        actions: [
          IconButton(
            tooltip: 'My Reports',
            icon: const Icon(Icons.history),
            onPressed: () => context.push(AppRoutes.myReports),
          ),
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push(AppRoutes.profile),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.submitReport),
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Report a Cat'),
      ),
      body: StreamBuilder<List<CatReport>>(
        stream: _reports,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _FeedMessage(
              icon: Icons.cloud_off_outlined,
              title: 'Could not load reports',
              subtitle: snapshot.error.toString(),
              onRetry: () => setState(() {
                _reports = _reportsService.watchAllReports();
              }),
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
                children: const [
                  SizedBox(height: 120),
                  _EmptyState(),
                ],
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.pagePadding,
      child: Column(
        children: [
          const Icon(
            Icons.pets_outlined,
            size: 64,
            color: AppColors.outline,
          ),
          const SizedBox(height: AppSpacing.stackLg),
          Text(
            'No reports yet',
            style: AppText.titleSm,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.stackSm),
          Text(
            'Be the first to report a stray cat on campus.',
            style: AppText.bodySm.copyWith(color: AppColors.outline),
            textAlign: TextAlign.center,
          ),
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
            Text(
              subtitle,
              style: AppText.bodySm.copyWith(color: AppColors.outline),
              textAlign: TextAlign.center,
            ),
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
