import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../models/cat_report.dart';
import '../services/reports_service.dart';
import '../widgets/report_card.dart';

/// All Reports — the full public feed (UC-06), reached from Home's
/// "View all". Lists every report with condition filtering, free-text
/// search, and a list ⇄ map toggle (the map plots every located sighting).
class ReportsFeedScreen extends StatefulWidget {
  const ReportsFeedScreen({super.key});

  @override
  State<ReportsFeedScreen> createState() => _ReportsFeedScreenState();
}

class _ReportsFeedScreenState extends State<ReportsFeedScreen> {
  final _reportsService = ReportsService();
  late Stream<List<CatReport>> _reports = _reportsService.watchAllReports();

  bool _mapView = false;
  CatCondition? _condition; // null = All
  String _query = '';
  bool _urgentFirst = false;

  Future<void> _refresh() async {
    setState(() => _reports = _reportsService.watchAllReports());
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  List<CatReport> _applyFilters(List<CatReport> all) {
    final q = _query.trim().toLowerCase();
    final filtered = all.where((r) {
      if (_condition != null && r.condition != _condition) return false;
      if (q.isEmpty) return true;
      return (r.locationLabel ?? '').toLowerCase().contains(q) ||
          r.description.toLowerCase().contains(q);
    }).toList();
    if (!_urgentFirst) return filtered;
    // Urgent cases float to the top; order within each group is preserved
    // (the stream is already newest-first), so this is a stable partition.
    final urgent = filtered.where(_isUrgent).toList();
    final rest = filtered.where((r) => !_isUrgent(r)).toList();
    return [...urgent, ...rest];
  }

  /// A case needs urgent attention when the cat is injured/sick and the
  /// report is still pending (not yet being handled or resolved).
  bool _isUrgent(CatReport r) =>
      (r.condition == CatCondition.injured ||
          r.condition == CatCondition.sick) &&
      r.status == ReportStatus.pending;

  bool _isLocated(CatReport r) =>
      r.location.latitude != 0 || r.location.longitude != 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Reports'),
        actions: [
          IconButton(
            tooltip: _mapView ? 'List view' : 'Map view',
            icon: Icon(_mapView ? Icons.view_list_outlined : Icons.map_outlined),
            onPressed: () => setState(() => _mapView = !_mapView),
          ),
        ],
      ),
      body: Column(
        children: [
          _filterBar(),
          Expanded(
            child: StreamBuilder<List<CatReport>>(
              stream: _reports,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _notice(
                    icon: Icons.cloud_off_outlined,
                    title: "Couldn't load reports",
                    message: 'Check your connection and try again.',
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final all = snapshot.data ?? const <CatReport>[];
                if (all.isEmpty) {
                  return _notice(
                    icon: Icons.pets_outlined,
                    title: 'No reports yet',
                    message: 'Sightings reported on campus will show up here.',
                  );
                }
                final filtered = _applyFilters(all);
                if (filtered.isEmpty) {
                  return _notice(
                    icon: Icons.search_off,
                    title: 'No matches',
                    message: 'Try a different filter or search term.',
                  );
                }
                return _mapView ? _mapBody(filtered) : _listBody(filtered);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Filters: search field + condition chips ─────────────────────────
  Widget _filterBar() {
    return Padding(
      padding: AppSpacing.horizontalPagePadding
          .copyWith(top: AppSpacing.stackSm, bottom: AppSpacing.stackSm),
      child: Column(
        children: [
          TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Search location or description',
              prefixIcon: const Icon(Icons.search, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.stackSm),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _urgentChip(),
                const SizedBox(width: AppSpacing.stackSm),
                _conditionChip('All', null),
                for (final c in CatCondition.values)
                  _conditionChip(c.label, c),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Sort toggle that floats urgent (injured/sick + pending) cases to the top.
  // Reuses the condition-chip styling; the flame uses the same red as the
  // injured condition badge (AppColors.error) so urgency reads consistently.
  Widget _urgentChip() {
    return FilterChip(
      label: const Text('Urgent first'),
      avatar: Icon(Icons.priority_high,
          size: 16,
          color: _urgentFirst ? AppColors.onPrimary : AppColors.error),
      selected: _urgentFirst,
      showCheckmark: false,
      onSelected: (v) => setState(() => _urgentFirst = v),
      selectedColor: AppColors.primaryContainer,
      labelStyle: AppText.labelCaps.copyWith(
        color: _urgentFirst ? AppColors.onPrimary : AppColors.onSurfaceVariant,
      ),
      backgroundColor: AppColors.secondaryContainer,
      side: BorderSide.none,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.pillRadius,
      ),
    );
  }

  Widget _conditionChip(String label, CatCondition? value) {
    final selected = _condition == value;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.stackSm),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => setState(() => _condition = value),
        selectedColor: AppColors.primaryContainer,
        labelStyle: AppText.labelCaps.copyWith(
          color: selected
              ? AppColors.onPrimary
              : AppColors.onSurfaceVariant,
        ),
        backgroundColor: AppColors.secondaryContainer,
        side: BorderSide.none,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.pillRadius,
        ),
      ),
    );
  }

  // ── List view ───────────────────────────────────────────────────────
  Widget _listBody(List<CatReport> reports) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(AppSpacing.stackLg, AppSpacing.stackSm,
            AppSpacing.stackLg, AppSpacing.stackLg),
        itemCount: reports.length,
        separatorBuilder: (_, _) =>
            const SizedBox(height: AppSpacing.stackSm + 4),
        itemBuilder: (context, i) {
          final r = reports[i];
          return ReportCard(
            report: r,
            showStatusBadge: true,
            onTap: () => context.push('${AppRoutes.reportDetail}/${r.id}'),
          );
        },
      ),
    );
  }

  // ── Map view ────────────────────────────────────────────────────────
  Widget _mapBody(List<CatReport> reports) {
    final located = reports.where(_isLocated).toList();
    if (located.isEmpty) {
      return _notice(
        icon: Icons.location_off_outlined,
        title: 'No mapped reports',
        message: 'None of these reports have a location yet.',
      );
    }
    final center = LatLng(
      located.map((r) => r.location.latitude).reduce((a, b) => a + b) /
          located.length,
      located.map((r) => r.location.longitude).reduce((a, b) => a + b) /
          located.length,
    );
    return FlutterMap(
      options: MapOptions(initialCenter: center, initialZoom: 14),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'my.utm.strayfriends',
          maxNativeZoom: 19,
        ),
        MarkerLayer(
          markers: [
            for (final r in located)
              Marker(
                point: LatLng(r.location.latitude, r.location.longitude),
                width: 44,
                height: 44,
                alignment: Alignment.topCenter,
                child: GestureDetector(
                  onTap: () =>
                      context.push('${AppRoutes.reportDetail}/${r.id}'),
                  child: Icon(
                    Icons.location_on,
                    color: _pinColor(r.condition),
                    size: 40,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Color _pinColor(CatCondition c) => switch (c) {
        CatCondition.injured => AppColors.error,
        CatCondition.sick => AppColors.primary,
        CatCondition.healthy => AppColors.tertiary,
      };

  Widget _notice({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: AppSpacing.pagePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.outline),
            const SizedBox(height: AppSpacing.stackMd),
            Text(title, style: AppText.titleSm, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.stackSm),
            Text(message,
                style: AppText.bodySm.copyWith(color: AppColors.outline),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
