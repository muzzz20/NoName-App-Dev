import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/donation.dart';
import 'payment_service.dart';

/// Firestore data layer for `donations` collection. NAD-26.
///
/// **Flow** (per NAD-26 AC):
///   1. UI calls [donate]
///   2. We call `PaymentService.processPayment` (NAD-21 simulation)
///   3. We write `donations/{id}` doc with the synchronous outcome —
///      `status: 'success'` (with `transactionId`) or `'failed'` (with
///      `failureCode`)
///   4. Cloud Function `onDonationCreate` (functions/index.js) reads
///      the new doc and, if `status='success'`, increments
///      `campaigns/{campaignId}.currentAmount` atomically. Failed
///      donations are recorded but do not contribute to the total.
///
/// **Why client-side write, not pending-then-update:**
///   - `firestore.rules` forbid client updates on `donations`
///     (anti-tampering — only the Cloud Function service account can
///     change a donation post-create).
///   - The simulation gateway returns the outcome synchronously, so the
///     client already knows the final status at write time.
///   - One Firestore write per donation instead of two.
///   - Sprint 4 real-gateway swap: PaymentService still returns
///     synchronously for one-shot card payments. For redirect-based
///     flows (FPX, Boost) we'll revisit — likely adding a webhook
///     Cloud Function that creates the donation server-side after the
///     redirect completes.
class DonationsService {
  DonationsService({
    FirebaseFirestore? firestore,
    PaymentService? paymentService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _paymentService = paymentService ?? PaymentService();

  final FirebaseFirestore _firestore;
  final PaymentService _paymentService;

  CollectionReference<Map<String, dynamic>> get _donations =>
      _firestore.collection('donations');

  /// Orchestrate one donation: payment then persistence.
  ///
  /// Returns the persisted [Donation]. The caller (UI) decides what to
  /// do based on `result.status` — show receipt for success, show
  /// retry CTA for failure.
  ///
  /// Throws [DonationFailure] on caller validation errors (amount <= 0)
  /// — same pattern as [PaymentFailure]. Gateway-side declines are
  /// returned as `Donation(status: failed)`, NOT thrown.
  Future<Donation> donate({
    required String donorId,
    required String campaignId,
    required int amountSen,
    String? donorName,
  }) async {
    if (amountSen <= 0) {
      throw const DonationFailure(
        'Donation amount must be greater than zero.',
      );
    }

    final result = await _paymentService.processPayment(
      amountSen: amountSen,
      donorId: donorId,
      campaignId: campaignId,
    );

    final docRef = _donations.doc();
    final donation = Donation(
      id: docRef.id,
      donorId: donorId,
      campaignId: campaignId,
      amountSen: amountSen,
      transactionId: result.transactionId,
      status: result.isSuccess
          ? DonationStatus.success
          : DonationStatus.failed,
      failureCode: result.failureCode?.storageKey,
      createdAt: DateTime.now().toUtc(),
      donorName: donorName,
    );
    await docRef.set(donation.toFirestore());
    return donation;
  }

  /// Stream of donations by a single donor, newest first.
  /// Powers "My Donations" history screen.
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

  /// Stream of all donations (any status) for a single campaign,
  /// newest first. Status filtering is done client-side at the limit
  /// of 100 — successful-only is used by the transparency report
  /// (NAD-27), all-status is used by admin reconciliation views.
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

  /// One-shot fetch of a single donation. Powers the receipt download
  /// flow and admin-side inspection.
  Future<Donation?> getDonation(String id) async {
    final snap = await _donations.doc(id).get();
    if (!snap.exists) return null;
    return Donation.fromFirestore(snap);
  }
}

/// Friendly caller-side validation failure (amount ≤ 0). Distinct from
/// a gateway-side decline which is returned as `Donation(status:
/// failed)` rather than thrown.
class DonationFailure implements Exception {
  final String message;
  const DonationFailure(this.message);

  @override
  String toString() => message;
}
