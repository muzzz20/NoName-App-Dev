import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../models/activity.dart';
import '../models/signup.dart';
import '../services/activities_service.dart';
import '../services/signups_service.dart';
import 'activity_format.dart';

/// UC-20 My Activities. The volunteer's joined activities in one list
/// (newest first); past ones are tagged with a "Past" pill.
class MyActivitiesScreen extends StatelessWidget {
  MyActivitiesScreen({super.key});

  final _signups = SignupsService();
  final _activities = ActivitiesService();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Activities'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/activities'),
        ),
      ),
      body: StreamBuilder<List<Signup>>(
        stream: _signups.watchSignupsByVolunteer(volunteerId: uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final signups = snap.data ?? [];
          if (signups.isEmpty) {
            return _empty(context);
          }
          return ListView.separated(
            padding: AppSpacing.pagePadding,
            itemCount: signups.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: AppSpacing.stackMd),
            itemBuilder: (context, i) => _SignupCard(
              signup: signups[i],
              activities: _activities,
            ),
          );
        },
      ),
    );
  }

  Widget _empty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.event_busy_outlined,
              size: 64, color: AppColors.outlineVariant),
          const SizedBox(height: AppSpacing.stackMd),
          Text("You haven't joined any activities yet.",
              style: AppText.bodyBase.copyWith(color: AppColors.secondary)),
          const SizedBox(height: AppSpacing.stackLg),
          ElevatedButton(
            onPressed: () => context.go('/activities'),
            child: const Text('Browse Activities'),
          ),
        ],
      ),
    );
  }
}

class _SignupCard extends StatelessWidget {
  final Signup signup;
  final ActivitiesService activities;
  const _SignupCard({required this.signup, required this.activities});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Activity?>(
      future: activities.getActivity(signup.activityId),
      builder: (context, snap) {
        final activity = snap.data;
        final title = activity?.title ?? 'Activity no longer available';
        final past = activity?.isPast ?? false;
        return InkWell(
          onTap: activity == null
              ? null
              : () => context.push('/activity/${activity.id}'),
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.stackMd),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                Icon(
                  past ? Icons.history : Icons.event_available,
                  color: past ? AppColors.secondary : AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.stackMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: AppText.bodyBase
                              .copyWith(fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      if (activity != null) ...[
                        const SizedBox(height: 2),
                        Text(formatActivityDateTime(activity.dateTime),
                            style: AppText.bodySm
                                .copyWith(color: AppColors.secondary)),
                      ],
                    ],
                  ),
                ),
                if (past)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text('Past',
                        style: AppText.bodySm
                            .copyWith(color: AppColors.secondary)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
