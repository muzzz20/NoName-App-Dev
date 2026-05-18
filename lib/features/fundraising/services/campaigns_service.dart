import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/campaign.dart';

/// Firestore data layer for `campaigns` collection. NAD-25.
///
/// Per NAD-25 AC:
/// - `campaigns/{id}` has title / description / goalAmount / currentAmount
///   / imageUrl / status / createdBy / createdAt / endsAt
/// - List active campaigns by createdAt (newest first) — powers UC-09
/// - Read single campaign by ID — powers UC-10 detail screen
/// - Admin-only create (Firestore rules enforced) — powers UC-15
///
/// Aggregation note: `currentAmount` is incremented by a Cloud Function
/// trigger on `donations/{id}` create (NAD-26). Clients MUST NOT write
/// that field directly — Firestore rules forbid it.
class CampaignsService {
  CampaignsService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _campaigns =>
      _firestore.collection('campaigns');

  /// Create a new campaign. Admin/NGO only — rules will reject regular users.
  ///
  /// Returns the created [Campaign] with assigned Firestore id.
  /// Callers should NOT pre-set an id.
  Future<Campaign> createCampaign({
    required String createdBy,
    required String title,
    required String description,
    required int goalAmountSen,
    String? imageUrl,
    DateTime? endsAt,
  }) async {
    if (title.trim().isEmpty) {
      throw const CampaignFailure('Campaign title is required.');
    }
    if (goalAmountSen <= 0) {
      throw const CampaignFailure('Goal amount must be greater than zero.');
    }
    if (endsAt != null && endsAt.isBefore(DateTime.now())) {
      throw const CampaignFailure('Campaign end date must be in the future.');
    }

    final docRef = _campaigns.doc();
    final campaign = Campaign(
      id: docRef.id,
      title: title.trim(),
      description: description.trim(),
      goalAmountSen: goalAmountSen,
      currentAmountSen: 0,
      imageUrl: imageUrl,
      status: CampaignStatus.active,
      createdBy: createdBy,
      createdAt: DateTime.now().toUtc(),
      endsAt: endsAt?.toUtc(),
    );
    await docRef.set(campaign.toFirestore());
    return campaign;
  }

  /// Stream of currently-active campaigns, newest first. Powers the
  /// public Browse Campaigns Feed (UC-09).
  ///
  /// Requires the composite index in `firestore.indexes.json`:
  /// (status ASC, createdAt DESC).
  Stream<List<Campaign>> watchActiveCampaigns({int limit = 50}) {
    return _campaigns
        .where('status', isEqualTo: CampaignStatus.active.storageKey)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(Campaign.fromFirestore).toList());
  }

  /// Stream of campaigns created by a specific admin/ngo user.
  /// Powers an Admin "My Campaigns" management list.
  Stream<List<Campaign>> watchCampaignsByCreator({
    required String createdBy,
    int limit = 50,
  }) {
    return _campaigns
        .where('createdBy', isEqualTo: createdBy)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(Campaign.fromFirestore).toList());
  }

  /// One-shot fetch of a single campaign by id. Powers UC-10 detail.
  Future<Campaign?> getCampaign(String id) async {
    final snap = await _campaigns.doc(id).get();
    if (!snap.exists) return null;
    return Campaign.fromFirestore(snap);
  }

  /// Live single-campaign stream — used by the detail screen so the
  /// goal progress bar updates in real time as donations come in.
  Stream<Campaign?> watchCampaign(String id) {
    return _campaigns.doc(id).snapshots().map((snap) {
      if (!snap.exists) return null;
      return Campaign.fromFirestore(snap);
    });
  }

  /// Admin/NGO — update mutable campaign fields (title, description,
  /// imageUrl, status, endsAt). `currentAmount` is server-managed and
  /// cannot be passed here (Firestore rules will not block it from this
  /// method, but the service intentionally omits it from the API).
  Future<void> updateCampaign({
    required String campaignId,
    String? title,
    String? description,
    String? imageUrl,
    CampaignStatus? status,
    DateTime? endsAt,
  }) async {
    final updates = <String, dynamic>{};
    if (title != null) updates['title'] = title.trim();
    if (description != null) updates['description'] = description.trim();
    if (imageUrl != null) updates['imageUrl'] = imageUrl;
    if (status != null) updates['status'] = status.storageKey;
    if (endsAt != null) updates['endsAt'] = Timestamp.fromDate(endsAt.toUtc());
    if (updates.isEmpty) return;
    await _campaigns.doc(campaignId).update(updates);
  }
}

/// Friendly error type for the UI. Mirrors AuthFailure / PhotoUploadFailure
/// patterns from Sprint 1.
class CampaignFailure implements Exception {
  final String message;
  const CampaignFailure(this.message);

  @override
  String toString() => message;
}
