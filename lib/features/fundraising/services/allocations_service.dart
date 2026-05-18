import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/allocation.dart';

/// Firestore data layer for `allocations` collection. NAD-27.
///
/// Admin / NGO records here are how a campaign's raised funds were
/// spent. Public read for transparency; admin/ngo create + update.
///
/// **Invariant** `sum(allocations.amount) <= campaign.currentAmount`
/// is enforced server-side by Cloud Function `onAllocationCreate`
/// (functions/index.js). If a client attempts a violating allocation
/// the Firestore write succeeds but the trigger rolls it back via
/// delete + emits an error log. Callers should poll the doc on a
/// short timeout after `createAllocation` to surface this.
class AllocationsService {
  AllocationsService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _allocations =>
      _firestore.collection('allocations');

  /// Create a new allocation. Admin/NGO only — rules will reject
  /// regular users. Returns the persisted [Allocation].
  Future<Allocation> createAllocation({
    required String campaignId,
    required int amountSen,
    required String purpose,
    required String createdBy,
    String? evidenceUrl,
  }) async {
    if (amountSen <= 0) {
      throw const AllocationFailure(
        'Allocation amount must be greater than zero.',
      );
    }
    if (purpose.trim().isEmpty) {
      throw const AllocationFailure('Purpose description is required.');
    }

    final docRef = _allocations.doc();
    final allocation = Allocation(
      id: docRef.id,
      campaignId: campaignId,
      amountSen: amountSen,
      purpose: purpose.trim(),
      evidenceUrl: evidenceUrl,
      createdBy: createdBy,
      createdAt: DateTime.now().toUtc(),
    );
    await docRef.set(allocation.toFirestore());
    return allocation;
  }

  /// Stream of allocations for a single campaign, newest first.
  /// Powers the transparency report's allocation list (NAD-27).
  Stream<List<Allocation>> watchAllocationsForCampaign({
    required String campaignId,
    int limit = 100,
  }) {
    return _allocations
        .where('campaignId', isEqualTo: campaignId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(Allocation.fromFirestore).toList());
  }

  /// One-shot fetch of a single allocation by id. Used by the admin
  /// edit screen (attach evidence URL after the fact).
  Future<Allocation?> getAllocation(String id) async {
    final snap = await _allocations.doc(id).get();
    if (!snap.exists) return null;
    return Allocation.fromFirestore(snap);
  }

  /// Admin/NGO — attach or update the evidence URL on an existing
  /// allocation (receipt photo uploaded to Supabase after the fact).
  Future<void> attachEvidence({
    required String allocationId,
    required String evidenceUrl,
  }) async {
    await _allocations.doc(allocationId).update({'evidenceUrl': evidenceUrl});
  }
}

class AllocationFailure implements Exception {
  final String message;
  const AllocationFailure(this.message);

  @override
  String toString() => message;
}
