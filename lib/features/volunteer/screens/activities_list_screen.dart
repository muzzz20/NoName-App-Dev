import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../auth/models/user_profile.dart';
import '../../auth/services/auth_service.dart';
import '../models/activity.dart';
import '../services/activities_service.dart';
import 'activity_format.dart';

/// UC-17 Browse Activities. Lists upcoming volunteer activities.
class ActivitiesListScreen extends StatefulWidget {
  const ActivitiesListScreen({super.key});

  @override
  State<ActivitiesListScreen> createState() => _ActivitiesListScreenState();
}

class _ActivitiesListScreenState extends State<ActivitiesListScreen> {
  final _service = ActivitiesService();
  final _authService = AuthService();
  UserProfile? _profile;

  bool get _isAdmin => _profile?.role == 'admin' || _profile?.role == 'ngo';

  @override
  void initState() {
    super.initState();
    if (FirebaseAuth.instance.currentUser != null) {
      _authService.loadProfile().then((p) {
        if (mounted) setState(() => _profile = p);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Volunteer Activities'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
        actions: [
          // Personal view — registered users only (hidden from visitors).
          if (FirebaseAuth.instance.currentUser != null)
            IconButton(
              tooltip: 'My Activities',
              icon: const Icon(Icons.event_available),
              onPressed: () => context.push('/my-activities'),
            ),
          // Admin/NGO only (UC-21/22) — was leaking to every signed-in user.
          if (_isAdmin)
            IconButton(
              tooltip: 'Manage (admin)',
              icon: const Icon(Icons.admin_panel_settings_outlined),
              onPressed: () => context.push('/admin-activity'),
            ),
        ],
      ),
      body: StreamBuilder<List<Activity>>(
        stream: _service.watchUpcomingActivities(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const _ErrorState();
          }
          final activities = (snapshot.data ?? [])
              .where((a) => !a.isPast)
              .toList();
          if (activities.isEmpty) {
            return const _EmptyState();
          }
          return ListView.separated(
            padding: AppSpacing.pagePadding,
            itemCount: activities.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: AppSpacing.stackMd),
            itemBuilder: (context, i) =>
                _ActivityCard(activity: activities[i]),
          );
        },
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final Activity activity;
  const _ActivityCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/activity/${activity.id}'),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.stackMd),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(activity.title,
                      style: AppText.titleSm,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ),
                _SlotsPill(activity: activity),
              ],
            ),
            const SizedBox(height: AppSpacing.stackSm),
            _iconRow(Icons.calendar_today, formatActivityDateTime(activity.dateTime)),
            const SizedBox(height: 4),
            _iconRow(Icons.location_on_outlined, activity.location),
          ],
        ),
      ),
    );
  }

  Widget _iconRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.secondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style: AppText.bodySm.copyWith(color: AppColors.secondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

class _SlotsPill extends StatelessWidget {
  final Activity activity;
  const _SlotsPill({required this.activity});

  @override
  Widget build(BuildContext context) {
    final full = activity.isFull;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: full ? AppColors.surfaceVariant : AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        full ? 'Full' : '${activity.slotsRemaining} left',
        style: AppText.bodySm.copyWith(
          color: full ? AppColors.secondary : AppColors.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.volunteer_activism_outlined,
              size: 64, color: AppColors.outlineVariant),
          const SizedBox(height: AppSpacing.stackMd),
          Text('No upcoming activities', style: AppText.titleSm),
          const SizedBox(height: AppSpacing.stackSm),
          Text('Check back soon for ways to help.',
              style: AppText.bodyBase.copyWith(color: AppColors.secondary)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.pagePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined,
                size: 56, color: AppColors.outline),
            const SizedBox(height: AppSpacing.stackMd),
            Text("Couldn't load activities",
                style: AppText.titleSm, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.stackSm),
            Text('Check your connection and try again.',
                textAlign: TextAlign.center,
                style: AppText.bodySm.copyWith(color: AppColors.outline)),
          ],
        ),
      ),
    );
  }
}
