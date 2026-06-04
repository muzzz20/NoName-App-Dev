import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/activity.dart';

/// Firestore data layer for `activities`. NAD-42.
///
/// Per AC: activities/{id} has title/description/location/dateTime/slots
/// /createdBy/status; list upcoming by dateTime; mark completed.
class ActivitiesService {
  ActivitiesService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _activities =>
      _firestore.collection('activities');

  /// Create an activity. Admin/NGO only (rules enforced). slotsRemaining
  /// starts equal to slots; status starts 'upcoming'.
  Future<Activity> createActivity({
    required String createdBy,
    required String title,
    required String description,
    required String location,
    required DateTime dateTime,
    required int slots,
    String? imageUrl,
  }) async {
    if (title.trim().isEmpty) {
      throw const ActivityFailure('Activity title is required.');
    }
    if (slots <= 0) {
      throw const ActivityFailure('Slots must be greater than zero.');
    }
    if (dateTime.isBefore(DateTime.now())) {
      throw const ActivityFailure('Activity date must be in the future.');
    }

    final docRef = _activities.doc();
    final activity = Activity(
      id: docRef.id,
      title: title.trim(),
      description: description.trim(),
      location: location.trim(),
      dateTime: dateTime.toUtc(),
      slots: slots,
      slotsRemaining: slots,
      imageUrl: imageUrl,
      createdBy: createdBy,
      status: ActivityStatus.upcoming,
      createdAt: DateTime.now().toUtc(),
    );
    await docRef.set(activity.toFirestore());
    return activity;
  }

  /// Stream of upcoming activities, soonest first. Powers UC-16.
  /// Past-dated activities are filtered client-side (a query can't mix
  /// an inequality on dateTime with the status equality without an extra
  /// composite index; for the project's scale client filter is fine).
  Stream<List<Activity>> watchUpcomingActivities({int limit = 50}) {
    return _activities
        .where('status', isEqualTo: ActivityStatus.upcoming.storageKey)
        .orderBy('dateTime')
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(Activity.fromFirestore).toList());
  }

  /// Stream of ALL activities, soonest first (admin management list).
  Stream<List<Activity>> watchAllActivities({int limit = 50}) {
    return _activities
        .orderBy('dateTime')
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(Activity.fromFirestore).toList());
  }

  /// Activities created by a specific admin/ngo.
  Stream<List<Activity>> watchActivitiesByCreator({
    required String createdBy,
    int limit = 50,
  }) {
    return _activities
        .where('createdBy', isEqualTo: createdBy)
        .orderBy('dateTime')
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(Activity.fromFirestore).toList());
  }

  Future<Activity?> getActivity(String id) async {
    final snap = await _activities.doc(id).get();
    if (!snap.exists) return null;
    return Activity.fromFirestore(snap);
  }

  Stream<Activity?> watchActivity(String id) {
    return _activities.doc(id).snapshots().map(
        (snap) => snap.exists ? Activity.fromFirestore(snap) : null);
  }

  /// Admin/NGO — edit mutable fields. `slotsRemaining` is managed by the
  /// sign-up transaction and intentionally not editable here.
  Future<void> updateActivity({
    required String activityId,
    String? title,
    String? description,
    String? location,
    DateTime? dateTime,
    ActivityStatus? status,
  }) async {
    final updates = <String, dynamic>{};
    if (title != null) updates['title'] = title.trim();
    if (description != null) updates['description'] = description.trim();
    if (location != null) updates['location'] = location.trim();
    if (dateTime != null) {
      updates['dateTime'] = Timestamp.fromDate(dateTime.toUtc());
    }
    if (status != null) updates['status'] = status.storageKey;
    if (updates.isEmpty) return;
    await _activities.doc(activityId).update(updates);
  }

  /// Admin/NGO — mark a past activity completed (UC-20).
  Future<void> markComplete(String activityId) =>
      _activities.doc(activityId).update(
          {'status': ActivityStatus.completed.storageKey});
}

class ActivityFailure implements Exception {
  final String message;
  const ActivityFailure(this.message);

  @override
  String toString() => message;
}
