import 'package:cloud_firestore/cloud_firestore.dart';

/// A volunteer's sign-up to an activity. Mirrors `signups/{id}`. NAD-43.
///
/// The doc ID is deterministic: `{activityId}_{volunteerId}`. This makes
/// duplicate sign-ups impossible (a second sign-up writes the same id)
/// and lets the sign-up transaction check existence with a single doc
/// read instead of a query (queries aren't allowed inside transactions).
class Signup {
  final String id;
  final String volunteerId;
  final String activityId;
  final DateTime signedAt;
  final String? volunteerName;

  const Signup({
    required this.id,
    required this.volunteerId,
    required this.activityId,
    required this.signedAt,
    this.volunteerName,
  });

  /// Deterministic composite id used as the Firestore doc id.
  static String idFor(String activityId, String volunteerId) =>
      '${activityId}_$volunteerId';

  Map<String, dynamic> toFirestore() => {
        'volunteerId': volunteerId,
        'activityId': activityId,
        'signedAt': Timestamp.fromDate(signedAt),
        if (volunteerName != null) 'volunteerName': volunteerName,
      };

  factory Signup.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Signup doc ${doc.id} is empty');
    }
    return Signup(
      id: doc.id,
      volunteerId: data['volunteerId'] as String? ?? '',
      activityId: data['activityId'] as String? ?? '',
      signedAt: (data['signedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      volunteerName: data['volunteerName'] as String?,
    );
  }
}
