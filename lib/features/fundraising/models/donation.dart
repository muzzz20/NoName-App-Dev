import 'package:cloud_firestore/cloud_firestore.dart';

/// Final outcome of a donation attempt at write time. Distinct from
/// a payment 'pending' lifecycle — Strayfriends donations are created
/// only AFTER PaymentService returns a synchronous outcome.
enum DonationStatus {
  success,
  failed;

  String get label => switch (this) {
        DonationStatus.success => 'Success',
        DonationStatus.failed => 'Failed',
      };

  String get storageKey => name;

  static DonationStatus tryParse(String? value) {
    if (value == null) return DonationStatus.failed;
    return DonationStatus.values
            .where((s) => s.storageKey == value.toLowerCase())
            .firstOrNull ??
        DonationStatus.failed;
  }
}

/// A persisted donation record. Mirrors `donations/{id}` Firestore doc.
///
/// `id` is the doc ID and is never stored inside the doc itself.
/// `amountSen` is in MYR sen (1 RM = 100 sen) to match Campaign money
/// units. `transactionId` is null for failed donations; `failureCode`
/// is null for successful donations.
/// `donorName` is denormalized from `users/{uid}.fullName` at write
/// time so the transparency report doesn't need a join.
class Donation {
  final String id;
  final String donorId;
  final String campaignId;
  final int amountSen;
  final String? transactionId;
  final DonationStatus status;
  final String? failureCode;
  final DateTime createdAt;
  final String? donorName;

  const Donation({
    required this.id,
    required this.donorId,
    required this.campaignId,
    required this.amountSen,
    required this.status,
    required this.createdAt,
    this.transactionId,
    this.failureCode,
    this.donorName,
  });

  Map<String, dynamic> toFirestore() => {
        'donorId': donorId,
        'campaignId': campaignId,
        'amount': amountSen,
        if (transactionId != null) 'transactionId': transactionId,
        'status': status.storageKey,
        if (failureCode != null) 'failureCode': failureCode,
        'createdAt': Timestamp.fromDate(createdAt),
        if (donorName != null) 'donorName': donorName,
      };

  factory Donation.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Donation doc ${doc.id} is empty');
    }
    return Donation(
      id: doc.id,
      donorId: data['donorId'] as String? ?? '',
      campaignId: data['campaignId'] as String? ?? '',
      amountSen: (data['amount'] as num?)?.toInt() ?? 0,
      transactionId: data['transactionId'] as String?,
      status: DonationStatus.tryParse(data['status'] as String?),
      failureCode: data['failureCode'] as String?,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      donorName: data['donorName'] as String?,
    );
  }
}
