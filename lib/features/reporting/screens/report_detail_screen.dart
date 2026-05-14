import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../auth/models/user_profile.dart';
import '../../auth/services/auth_service.dart';
import '../models/cat_report.dart';
import '../services/reports_service.dart';
import '../widgets/condition_badge.dart';

/// Report Detail (NAD-13) — UC-07. Shows the full report with photo hero,
/// status, condition, description, location (lat/lng + label), reporter,
/// and timestamp. Map preview is a static placeholder; live Google Map
/// renderer lands in Sprint 3 via google_maps_flutter.
class ReportDetailScreen extends StatefulWidget {
  final String reportId;
  const ReportDetailScreen({super.key, required this.reportId});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  final _reportsService = ReportsService();
  final _authService = AuthService();

  late final Future<_DetailPayload> _payload = _load();

  Future<_DetailPayload> _load() async {
    final report = await _reportsService.getReport(widget.reportId);
    if (report == null) {
      throw StateError('Report ${widget.reportId} not found');
    }
    final reporter = await _authService.loadProfile(uid: report.userId);
    return _DetailPayload(report: report, reporter: reporter);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<_DetailPayload>(
        future: _payload,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _NotFound(message: snapshot.error.toString());
          }
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          return _DetailBody(payload: snapshot.data!);
        },
      ),
    );
  }
}

class _DetailPayload {
  final CatReport report;
  final UserProfile? reporter;
  _DetailPayload({required this.report, required this.reporter});
}

class _DetailBody extends StatelessWidget {
  final _DetailPayload payload;
  const _DetailBody({required this.payload});

  @override
  Widget build(BuildContext context) {
    final r = payload.report;
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          leading: Padding(
            padding: const EdgeInsets.all(AppSpacing.stackSm),
            child: Material(
              shape: const CircleBorder(),
              color: AppColors.surfaceContainerLowest.withValues(alpha: 0.85),
              child: IconButton(
                icon: const Icon(Icons.chevron_left, color: AppColors.primary),
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.go('/home'),
              ),
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: r.photoUrl.isEmpty
                ? Container(
                    color: AppColors.surfaceContainer,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.pets,
                      size: 64,
                      color: AppColors.outline,
                    ),
                  )
                : Image.network(
                    r.photoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: AppColors.surfaceContainer,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.broken_image_outlined,
                        size: 48,
                        color: AppColors.outline,
                      ),
                    ),
                  ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: AppSpacing.pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        r.locationLabel?.isNotEmpty == true
                            ? r.locationLabel!
                            : 'Location',
                        style: AppText.titleSm,
                      ),
                    ),
                    ConditionBadge(condition: r.condition),
                  ],
                ),
                const SizedBox(height: AppSpacing.stackXs),
                Text(
                  'Status: ${r.status.label}',
                  style: AppText.bodySm.copyWith(color: AppColors.outline),
                ),

                const SizedBox(height: AppSpacing.stackLg),

                if (r.description.isNotEmpty) ...[
                  _SectionTitle(
                    icon: Icons.info_outline,
                    label: 'Condition description',
                  ),
                  const SizedBox(height: AppSpacing.stackSm),
                  Card(
                    child: Padding(
                      padding: AppSpacing.pagePadding,
                      child: Text(r.description, style: AppText.bodyBase),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.stackLg),
                ],

                _SectionTitle(
                  icon: Icons.place_outlined,
                  label: 'Location',
                ),
                const SizedBox(height: AppSpacing.stackSm),
                _MapPreview(location: r.location, label: r.locationLabel),
                const SizedBox(height: AppSpacing.stackLg),

                Row(
                  children: [
                    Expanded(
                      child: _MetaTile(
                        icon: Icons.person_outline,
                        label: 'Reporter',
                        value: payload.reporter?.fullName ?? 'Unknown',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.stackSm + 4),
                    Expanded(
                      child: _MetaTile(
                        icon: Icons.calendar_today_outlined,
                        label: 'Reported',
                        value: _formatDate(r.createdAt),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.stackXl),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionTitle({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 16),
        const SizedBox(width: 6),
        Text(label, style: AppText.labelCaps),
      ],
    );
  }
}

class _MapPreview extends StatelessWidget {
  final GeoPoint location;
  final String? label;
  const _MapPreview({required this.location, this.label});

  @override
  Widget build(BuildContext context) {
    // Static placeholder. Sprint 3 swaps this for google_maps_flutter.
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: AppColors.secondaryContainer,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.cardBorder),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.place, color: AppColors.onPrimary),
          ),
          const SizedBox(height: AppSpacing.stackSm),
          Text(
            '${location.latitude.toStringAsFixed(5)}, '
            '${location.longitude.toStringAsFixed(5)}',
            style: AppText.bodySm.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _MetaTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _MetaTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.stackMd),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 16),
            ),
            const SizedBox(width: AppSpacing.stackSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppText.labelCaps),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: AppText.bodySm
                        .copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotFound extends StatelessWidget {
  final String message;
  const _NotFound({required this.message});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: AppSpacing.pagePadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 48, color: AppColors.outline),
            const SizedBox(height: AppSpacing.stackMd),
            Text(
              'Report not found',
              style: AppText.titleSm,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.stackSm),
            Text(
              message,
              style: AppText.bodySm.copyWith(color: AppColors.outline),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.stackLg),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Back to Feed'),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime when) {
  final local = when.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  return '$day/$month/${local.year}';
}
