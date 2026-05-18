import 'package:cloud_firestore/cloud_firestore.dart';

/// A spend record against a campaign's raised funds. NAD-27.
///
/// Each allocation describes how a chunk of the campaign's raised
/// money was spent (e.g. "Vet bill for cat at Block L50 — RM 350").
/// The transparency report (`TransparencyService.getReport`) sums
/// allocations and shows the list publicly.
///
/// **Invariant** (enforced server-side by Cloud Function
/// `onAllocationCreate` in functions/index.js):
///   sum(allocations.amount for campaign X) <= campaign.currentAmount
/// Allocations that would violate this are rolled back via delete.
///
/// `id` is the doc ID and is never stored inside the doc itself.
/// `amountSen` is in MYR sen (1 RM = 100 sen).
class Allocation {
  final String id;
  final String campaignId;
  final int amountSen;
  final String purpose;
  final String? evidenceUrl;
  final String createdBy;
  final DateTime createdAt;

  const Allocation({
    required this.id,
    required this.campaignId,
    required this.amountSen,
    required this.purpose,
    required this.createdBy,
    required this.createdAt,
    this.evidenceUrl,
  });

  Map<String, dynamic> toFirestore() => {
        'campaignId': campaignId,
        'amount': amountSen,
        'purpose': purpose,
        if (evidenceUrl != null) 'evidenceUrl': evidenceUrl,
        'createdBy': createdBy,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory Allocation.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Allocation doc ${doc.id} is empty');
    }
    return Allocation(
      id: doc.id,
      campaignId: data['campaignId'] as String? ?? '',
      amountSen: (data['amount'] as num?)?.toInt() ?? 0,
      purpose: data['purpose'] as String? ?? '',
      evidenceUrl: data['evidenceUrl'] as String?,
      createdBy: data['createdBy'] as String? ?? '',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
