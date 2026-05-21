import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../models/activity.dart';
import '../services/activities_service.dart';
import '../services/signups_service.dart';
import 'activity_format.dart';

/// UC-17 View Activity Detail + Sign Up / Cancel.
class ActivityDetailScreen extends StatefulWidget {
  final String activityId;
  const ActivityDetailScreen({super.key, required this.activityId});

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  final _activities = ActivitiesService();
  final _signups = SignupsService();
  bool _busy = false;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> _toggleSignup(bool currentlyJoined) async {
    setState(() => _busy = true);
    try {
      if (currentlyJoined) {
        await _signups.cancelSignup(
            activityId: widget.activityId, volunteerId: _uid);
        _snack('Sign-up cancelled.');
      } else {
        final name = FirebaseAuth.instance.currentUser?.displayName;
        await _signups.signUp(
            activityId: widget.activityId,
            volunteerId: _uid,
            volunteerName: name);
        _snack('You are signed up. Thank you!');
      }
    } on SignupFailure catch (e) {
      _snack(e.message, error: true);
    } catch (e) {
      _snack('Something went wrong. Please try again.', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.error : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/activities'),
        ),
      ),
      body: StreamBuilder<Activity?>(
        stream: _activities.watchActivity(widget.activityId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final activity = snap.data;
          if (activity == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 64, color: AppColors.error),
                  const SizedBox(height: AppSpacing.stackMd),
                  Text('Activity not found.', style: AppText.bodyBase),
                ],
              ),
            );
          }
          return _content(activity);
        },
      ),
    );
  }

  Widget _content(Activity activity) {
    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(activity.title, style: AppText.displayLg),
          const SizedBox(height: AppSpacing.stackMd),
          _infoRow(Icons.calendar_today,
              formatActivityDateTime(activity.dateTime)),
          const SizedBox(height: AppSpacing.stackSm),
          _infoRow(Icons.location_on_outlined, activity.location),
          const SizedBox(height: AppSpacing.stackSm),
          _infoRow(Icons.group_outlined,
              '${activity.volunteerCount} joined · ${activity.slotsRemaining} of ${activity.slots} slots left'),
          const SizedBox(height: AppSpacing.stackLg),
          const Divider(),
          const SizedBox(height: AppSpacing.stackLg),
          Text('About', style: AppText.titleSm),
          const SizedBox(height: AppSpacing.stackSm),
          Text(
            activity.description.isEmpty
                ? 'No description provided.'
                : activity.description,
            style: AppText.bodyBase.copyWith(color: AppColors.secondary),
          ),
          const SizedBox(height: AppSpacing.stackXl),
          _signupButton(activity),
        ],
      ),
    );
  }

  Widget _signupButton(Activity activity) {
    if (activity.status != ActivityStatus.upcoming || activity.isPast) {
      return _disabledButton('Activity closed');
    }
    return StreamBuilder<bool>(
      stream: _signups.watchIsSignedUp(
          activityId: widget.activityId, volunteerId: _uid),
      builder: (context, snap) {
        final joined = snap.data ?? false;
        if (!joined && activity.isFull) {
          return _disabledButton('Activity full');
        }
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _busy ? null : () => _toggleSignup(joined),
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(joined ? Icons.close : Icons.check),
            label: Text(joined ? 'Cancel Sign-Up' : 'Sign Up'),
            style: joined
                ? ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surfaceVariant,
                    foregroundColor: AppColors.onSurface,
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _disabledButton(String label) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: null,
        child: Text(label),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: AppSpacing.stackSm),
        Expanded(child: Text(text, style: AppText.bodyBase)),
      ],
    );
  }
}
