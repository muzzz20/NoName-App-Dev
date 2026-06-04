import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/activity.dart';
import '../models/signup.dart';

/// Firestore data layer for `signups`. NAD-43.
///
/// Sign-up is a **client-side Firestore transaction** so the slot
/// decrement, the full-capacity rejection, and the duplicate check are
/// all atomic and synchronous (no Cloud Function lag — the user gets an
/// immediate "full" / "already signed up" error):
///   1. read the activity doc
///   2. read the deterministic signup doc ({activityId}_{volunteerId})
///   3. reject if activity full, past, cancelled, or already signed up
///   4. decrement activity.slotsRemaining + create the signup atomically
///
/// Cancelling reverses it: delete the signup + increment slotsRemaining.
class SignupsService {
  SignupsService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _signups =>
      _firestore.collection('signups');
  CollectionReference<Map<String, dynamic>> get _activities =>
      _firestore.collection('activities');

  /// Sign the volunteer up for the activity. Throws [SignupFailure] with
  /// a friendly message if the activity is full / past / already joined.
  Future<void> signUp({
    required String activityId,
    required String volunteerId,
    String? volunteerName,
  }) async {
    final activityRef = _activities.doc(activityId);
    final signupRef = _signups.doc(Signup.idFor(activityId, volunteerId));

    await _firestore.runTransaction((tx) async {
      final activitySnap = await tx.get(activityRef);
      if (!activitySnap.exists) {
        throw const SignupFailure('Activity not found.');
      }
      final data = activitySnap.data()!;
      final status = ActivityStatus.tryParse(data['status'] as String?);
      if (status != ActivityStatus.upcoming) {
        throw const SignupFailure('This activity is no longer open.');
      }
      final dateTime =
          (data['dateTime'] as Timestamp?)?.toDate() ?? DateTime.now();
      if (dateTime.isBefore(DateTime.now())) {
        throw const SignupFailure('This activity has already passed.');
      }
      final signupSnap = await tx.get(signupRef);
      if (signupSnap.exists) {
        throw const SignupFailure('You have already signed up.');
      }
      final remaining = (data['slotsRemaining'] as num?)?.toInt() ?? 0;
      if (remaining <= 0) {
        throw const SignupFailure('This activity is full.');
      }

      tx.update(activityRef, {'slotsRemaining': remaining - 1});
      tx.set(
        signupRef,
        Signup(
          id: signupRef.id,
          volunteerId: volunteerId,
          activityId: activityId,
          signedAt: DateTime.now().toUtc(),
          volunteerName: volunteerName,
        ).toFirestore(),
      );
    });
  }

  /// Cancel a sign-up: delete it + free the slot atomically.
  Future<void> cancelSignup({
    required String activityId,
    required String volunteerId,
  }) async {
    final activityRef = _activities.doc(activityId);
    final signupRef = _signups.doc(Signup.idFor(activityId, volunteerId));

    await _firestore.runTransaction((tx) async {
      final signupSnap = await tx.get(signupRef);
      if (!signupSnap.exists) return; // already cancelled — no-op
      final activitySnap = await tx.get(activityRef);
      if (activitySnap.exists) {
        final remaining =
            (activitySnap.data()!['slotsRemaining'] as num?)?.toInt() ?? 0;
        final total = (activitySnap.data()!['slots'] as num?)?.toInt() ?? 0;
        // Clamp so we never exceed capacity if data is stale.
        final restored = (remaining + 1) > total ? total : remaining + 1;
        tx.update(activityRef, {'slotsRemaining': restored});
      }
      tx.delete(signupRef);
    });
  }

  /// Whether this volunteer is signed up for this activity (one-shot).
  Future<bool> isSignedUp({
    required String activityId,
    required String volunteerId,
  }) async {
    final snap =
        await _signups.doc(Signup.idFor(activityId, volunteerId)).get();
    return snap.exists;
  }

  /// Live "am I signed up?" stream for the activity detail button state.
  Stream<bool> watchIsSignedUp({
    required String activityId,
    required String volunteerId,
  }) {
    return _signups
        .doc(Signup.idFor(activityId, volunteerId))
        .snapshots()
        .map((snap) => snap.exists);
  }

  /// Stream the signups for one volunteer (My Activities — UC-18).
  Stream<List<Signup>> watchSignupsByVolunteer({
    required String volunteerId,
    int limit = 50,
  }) {
    return _signups
        .where('volunteerId', isEqualTo: volunteerId)
        .orderBy('signedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(Signup.fromFirestore).toList());
  }

  /// Stream the signups for one activity (admin sees volunteers — UC-19).
  Stream<List<Signup>> watchSignupsForActivity({
    required String activityId,
    int limit = 200,
  }) {
    return _signups
        .where('activityId', isEqualTo: activityId)
        .orderBy('signedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(Signup.fromFirestore).toList());
  }
}

class SignupFailure implements Exception {
  final String message;
  const SignupFailure(this.message);

  @override
  String toString() => message;
}
