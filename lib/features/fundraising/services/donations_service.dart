import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/donation.dart';

/// Firestore read layer for `donations`. NAD-26.
///
/// **Donations are written server-side only** by the `stripeWebhook`
/// Cloud Function after Stripe confirms a payment (NAD-21). The client
/// never creates a donation doc — `firestore.rules` deny client writes
/// to this collection. This service therefore exposes reads only, plus
/// a session-correlation stream for the receipt screen.
class DonationsService {
  DonationsService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _donations =>
      _firestore.collection('donations');

  /// Stream of donations by a single donor, newest first.
  /// Powers "My Donations" history.
  Stream<List<Donation>> watchDonationsByDonor({
    required String donorId,
    int limit = 50,
  }) {
    return _donations
        .where('donorId', isEqualTo: donorId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(Donation.fromFirestore).toList());
  }

  /// Stream of donations (optionally success-only) for a campaign,
  /// newest first. Feeds the transparency report (NAD-27) and admin
  /// reconciliation. Status filter applied client-side at the limit.
  Stream<List<Donation>> watchDonationsForCampaign({
    required String campaignId,
    int limit = 100,
    bool successOnly = false,
  }) {
    return _donations
        .where('campaignId', isEqualTo: campaignId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) {
      final donations = snap.docs.map(Donation.fromFirestore);
      if (!successOnly) return donations.toList();
      return donations
          .where((d) => d.status == DonationStatus.success)
          .toList();
    });
  }

  /// Stream the donation correlated to a Stripe Checkout session, scoped to
  /// the [donorId] who paid.
  ///
  /// The `donorId` filter is REQUIRED, not optional: the donations read rule
  /// only lets a donor read their own docs, and Firestore rejects a query
  /// wholesale (permission-denied) unless it is constrained to satisfy that
  /// rule. Filtering by `stripeSessionId` alone was denied — leaving the
  /// receipt stuck on "confirming". Two equality filters need no composite
  /// index. Emits null until the webhook writes the donation (usually < 2s).
  Stream<Donation?> watchDonationBySession({
    required String sessionId,
    required String donorId,
  }) {
    return _donations
        .where('stripeSessionId', isEqualTo: sessionId)
        .where('donorId', isEqualTo: donorId)
        .limit(1)
        .snapshots()
        .map((snap) =>
            snap.docs.isEmpty ? null : Donation.fromFirestore(snap.docs.first));
  }

  /// One-shot fetch of a single donation by id.
  Future<Donation?> getDonation(String id) async {
    final snap = await _donations.doc(id).get();
    if (!snap.exists) return null;
    return Donation.fromFirestore(snap);
  }
}
