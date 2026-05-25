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

/// UC-21 Admin Create Activity + UC-22 Mark Complete.
/// Admin/NGO only — Firestore rules independently reject non-admins.
class AdminManageActivityScreen extends StatelessWidget {
  AdminManageActivityScreen({super.key});

  final _activities = ActivitiesService();
  final _signups = SignupsService();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Activities'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/activities'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateSheet(context, uid),
        icon: const Icon(Icons.add),
        label: const Text('New Activity'),
      ),
      body: StreamBuilder<List<Activity>>(
        stream: _activities.watchActivitiesByCreator(createdBy: uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final activities = snap.data ?? [];
          if (activities.isEmpty) {
            return Center(
              child: Text('No activities yet. Tap "New Activity".',
                  style:
                      AppText.bodyBase.copyWith(color: AppColors.secondary)),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.stackLg, AppSpacing.stackLg, AppSpacing.stackLg, 96),
            itemCount: activities.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: AppSpacing.stackMd),
            itemBuilder: (context, i) => _AdminActivityCard(
              activity: activities[i],
              activitiesService: _activities,
              signupsService: _signups,
            ),
          );
        },
      ),
    );
  }

  void _openCreateSheet(BuildContext context, String uid) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CreateActivitySheet(
        createdBy: uid,
        service: _activities,
      ),
    );
  }
}

class _AdminActivityCard extends StatelessWidget {
  final Activity activity;
  final ActivitiesService activitiesService;
  final SignupsService signupsService;

  const _AdminActivityCard({
    required this.activity,
    required this.activitiesService,
    required this.signupsService,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                      overflow: TextOverflow.ellipsis)),
              Text(activity.status.label,
                  style: AppText.bodySm.copyWith(color: AppColors.secondary)),
            ],
          ),
          const SizedBox(height: 4),
          Text(formatActivityDateTime(activity.dateTime),
              style: AppText.bodySm.copyWith(color: AppColors.secondary)),
          Text('${activity.volunteerCount}/${activity.slots} volunteers',
              style: AppText.bodySm.copyWith(color: AppColors.secondary)),
          const SizedBox(height: AppSpacing.stackSm),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => _showVolunteers(context),
                icon: const Icon(Icons.group_outlined, size: 18),
                label: const Text('Volunteers'),
              ),
              const Spacer(),
              if (activity.status == ActivityStatus.upcoming)
                TextButton(
                  onPressed: () => _confirmComplete(context),
                  child: const Text('Mark Complete'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // UC-22: confirm before marking complete (irreversible — closes sign-ups).
  Future<void> _confirmComplete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark activity complete?'),
        content: const Text(
            'Volunteers can no longer sign up, and this cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Mark Complete')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await activitiesService.markComplete(activity.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activity marked complete.')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Couldn't mark complete. Please try again."),
        backgroundColor: AppColors.error,
      ));
    }
  }

  void _showVolunteers(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => Padding(
        padding: AppSpacing.pagePadding,
        child: StreamBuilder<List<Signup>>(
          stream:
              signupsService.watchSignupsForActivity(activityId: activity.id),
          builder: (context, snap) {
            final signups = snap.data ?? [];
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Volunteers (${signups.length})',
                    style: AppText.titleSm),
                const SizedBox(height: AppSpacing.stackMd),
                if (signups.isEmpty)
                  Text('No volunteers yet.',
                      style: AppText.bodyBase
                          .copyWith(color: AppColors.secondary))
                else
                  ...signups.map((s) => ListTile(
                        dense: true,
                        leading: const Icon(Icons.person_outline),
                        title: Text(s.volunteerName ?? s.volunteerId),
                        subtitle: Text(formatActivityDateTime(s.signedAt)),
                      )),
                const SizedBox(height: AppSpacing.stackMd),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CreateActivitySheet extends StatefulWidget {
  final String createdBy;
  final ActivitiesService service;
  const _CreateActivitySheet({required this.createdBy, required this.service});

  @override
  State<_CreateActivitySheet> createState() => _CreateActivitySheetState();
}

class _CreateActivitySheetState extends State<_CreateActivitySheet> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _location = TextEditingController();
  final _slots = TextEditingController();
  DateTime? _dateTime;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _location.dispose();
    _slots.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDate: now.add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (time == null) return;
    setState(() {
      _dateTime = DateTime(
          date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dateTime == null) {
      _snack('Please pick a date and time.', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.service.createActivity(
        createdBy: widget.createdBy,
        title: _title.text,
        description: _description.text,
        location: _location.text,
        dateTime: _dateTime!,
        slots: int.tryParse(_slots.text) ?? 0,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activity created.')),
      );
    } on ActivityFailure catch (e) {
      _snack(e.message, error: true);
    } catch (e) {
      _snack('Could not create activity.', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.error : null,
    ));
  }

  // The global input theme is borderless-filled (relies on background
  // contrast). On this near-white bottom sheet the faint fill is invisible,
  // so give the fields a soft visible outline. Maroon focus + red error still
  // come from the theme.
  InputDecoration _fieldDec(String label, {String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputRadius,
          borderSide: const BorderSide(color: AppColors.surfaceDim),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.stackLg,
        right: AppSpacing.stackLg,
        top: AppSpacing.stackLg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.stackLg,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('New Activity', style: AppText.titleSm),
              const SizedBox(height: AppSpacing.stackMd),
              TextFormField(
                controller: _title,
                decoration: _fieldDec('Title'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: AppSpacing.stackSm),
              TextFormField(
                controller: _description,
                decoration: _fieldDec('Description'),
                maxLines: 3,
              ),
              const SizedBox(height: AppSpacing.stackSm),
              TextFormField(
                controller: _location,
                decoration: _fieldDec('Location'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: AppSpacing.stackSm),
              TextFormField(
                controller: _slots,
                keyboardType: TextInputType.number,
                decoration: _fieldDec('Number of slots'),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n <= 0) return 'Enter a positive number';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.stackMd),
              OutlinedButton.icon(
                onPressed: _pickDateTime,
                icon: const Icon(Icons.calendar_today, size: 18),
                label: Text(_dateTime == null
                    ? 'Pick date & time'
                    : formatActivityDateTime(_dateTime!.toUtc())),
              ),
              const SizedBox(height: AppSpacing.stackLg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Create Activity'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
