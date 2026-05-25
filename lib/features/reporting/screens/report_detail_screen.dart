import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../auth/services/auth_service.dart';
import '../models/cat_report.dart';
import '../services/reports_service.dart';
import '../widgets/condition_badge.dart';
import '../widgets/static_map.dart';
import '../widgets/status_badge.dart';
import '../widgets/status_timeline.dart';

/// Report Detail (NAD-13) — UC-07. Shows the full report with photo hero,
/// status (badge + lifecycle timeline), condition, description, an
/// OpenStreetMap location preview (tap → open in the device's maps app),
/// reporter, and timestamp.
class ReportDetailScreen extends StatefulWidget {
  final String reportId;
  const ReportDetailScreen({super.key, required this.reportId});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  final _reportsService = ReportsService();
  final _authService = AuthService();

  late Future<_DetailPayload> _payload;
  String? _role;
  bool get _isAdmin => _role == 'admin' || _role == 'ngo';

  @override
  void initState() {
    super.initState();
    _payload = _load();
    _loadRole();
  }

  Future<void> _loadRole() async {
    if (FirebaseAuth.instance.currentUser == null) return;
    try {
      final p = await _authService.loadProfile();
      if (mounted) setState(() => _role = p?.role);
    } catch (_) {/* stays null → no admin control shown */}
  }

  // UC-09: admin/NGO moves the report through its lifecycle. Rule-backed —
  // firestore.rules `reports` update = isAdminOrNgo().
  Future<void> _updateStatus(ReportStatus status) async {
    try {
      await _reportsService.updateStatus(
          reportId: widget.reportId, status: status);
      if (!mounted) return;
      setState(() => _payload = _load());
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to ${status.label}.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Couldn't update status. Please try again."),
        backgroundColor: AppColors.error,
      ));
    }
  }

  Future<_DetailPayload> _load() async {
    final report = await _reportsService.getReport(widget.reportId);
    if (report == null) {
      throw StateError('Report ${widget.reportId} not found');
    }
    // Prefer the denormalized reporter name (readable by everyone incl.
    // visitors). Legacy reports lack it: a signed-in user can still resolve
    // it from the auth-gated users doc; visitors fall back to a generic
    // label since they cannot read the users collection.
    var reporterName = report.reporterName;
    if ((reporterName == null || reporterName.isEmpty) &&
        FirebaseAuth.instance.currentUser != null) {
      try {
        reporterName =
            (await _authService.loadProfile(uid: report.userId))?.fullName;
      } catch (_) {
        // Ignore — keep null, generic label is shown.
      }
    }
    return _DetailPayload(report: report, reporterName: reporterName);
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
          final report = snapshot.data!.report;
          return _DetailBody(
            payload: snapshot.data!,
            isAdmin: _isAdmin,
            // Owner may edit their OWN report only while it is still pending.
            canEdit: report.userId == FirebaseAuth.instance.currentUser?.uid &&
                report.status == ReportStatus.pending,
            onUpdateStatus: _updateStatus,
          );
        },
      ),
    );
  }
}

class _DetailPayload {
  final CatReport report;
  final String? reporterName;
  _DetailPayload({required this.report, required this.reporterName});
}

class _DetailBody extends StatelessWidget {
  final _DetailPayload payload;
  final bool isAdmin;
  final bool canEdit;
  final void Function(ReportStatus) onUpdateStatus;
  const _DetailBody({
    required this.payload,
    required this.isAdmin,
    required this.canEdit,
    required this.onUpdateStatus,
  });

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
                const SizedBox(height: AppSpacing.stackSm),
                // Labelled "Sighting status" to distinguish this single
                // sighting from the cat's overall "Care status" (cat profile).
                Text('Sighting status', style: AppText.labelCaps),
                const SizedBox(height: AppSpacing.stackXs),
                Align(
                  alignment: Alignment.centerLeft,
                  child: StatusBadge(status: r.status),
                ),

                const SizedBox(height: AppSpacing.stackLg),
                StatusTimeline(status: r.status),

                if (isAdmin) ...[
                  const SizedBox(height: AppSpacing.stackLg),
                  _SectionTitle(
                    icon: Icons.admin_panel_settings_outlined,
                    label: 'Update status (admin)',
                  ),
                  const SizedBox(height: AppSpacing.stackSm),
                  Wrap(
                    spacing: AppSpacing.stackSm,
                    runSpacing: AppSpacing.stackSm,
                    children: [
                      for (final s in ReportStatus.values)
                        ChoiceChip(
                          label: Text(s.label),
                          selected: r.status == s,
                          showCheckmark: false,
                          onSelected:
                              r.status == s ? null : (_) => onUpdateStatus(s),
                          selectedColor: AppColors.primaryContainer,
                          labelStyle: AppText.labelCaps.copyWith(
                            color: r.status == s
                                ? AppColors.onPrimary
                                : AppColors.onSurfaceVariant,
                          ),
                          backgroundColor: AppColors.secondaryContainer,
                          side: BorderSide.none,
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.pillRadius,
                          ),
                        ),
                    ],
                  ),
                ],

                if (canEdit) ...[
                  const SizedBox(height: AppSpacing.stackMd),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      // Reuse the submit form in edit mode (passes the report).
                      onPressed: () => context.push('/report/new', extra: r),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit report'),
                    ),
                  ),
                ],

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
                GestureDetector(
                  onTap: () => _openInMaps(
                      r.location.latitude, r.location.longitude),
                  child: StaticMap(point: r.location),
                ),
                const SizedBox(height: AppSpacing.stackSm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () => _openInMaps(
                        r.location.latitude, r.location.longitude),
                    icon: const Icon(Icons.directions_outlined, size: 18),
                    label: const Text('Open in Maps'),
                  ),
                ),
                const SizedBox(height: AppSpacing.stackLg),

                Row(
                  children: [
                    Expanded(
                      child: _MetaTile(
                        icon: Icons.person_outline,
                        label: 'Reporter',
                        value: payload.reporterName?.isNotEmpty == true
                            ? payload.reporterName!
                            : 'Community member',
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
                    maxLines: 2,
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

/// Launch the device's maps app at [lat],[lng] (best-effort; silent on
/// platforms without a maps handler).
Future<void> _openInMaps(double lat, double lng) async {
  final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng');
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// Horizontal lifecycle stepper: Pending → In progress → Resolved, with the
/// current stage filled. A rejected report shows a dedicated banner instead.
