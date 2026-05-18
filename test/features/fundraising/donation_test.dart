// Unit tests for the Donation model + enums (NAD-26 / NAD-34).
// Pure-function tests — no Firebase / network mocks needed.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strayfriends/features/fundraising/models/donation.dart';

void main() {
  group('DonationStatus.tryParse', () {
    test('parses each storageKey case-insensitively', () {
      expect(DonationStatus.tryParse('success'), DonationStatus.success);
      expect(DonationStatus.tryParse('FAILED'), DonationStatus.failed);
    });
    test('falls back to failed on null or unknown', () {
      expect(DonationStatus.tryParse(null), DonationStatus.failed);
      expect(DonationStatus.tryParse('processing'), DonationStatus.failed);
    });
  });

  group('Donation.toFirestore', () {
    test('successful donation includes transactionId + donorName, no failureCode', () {
      final created = DateTime.utc(2026, 5, 18, 14, 30);
      final donation = Donation(
        id: 'd1',
        donorId: 'donor-uid-1',
        campaignId: 'c1',
        amountSen: 5000, // RM 50.00
        transactionId: 'sim_tx_1700000000000_abc123',
        status: DonationStatus.success,
        createdAt: created,
        donorName: 'Jane Doe',
      );

      final map = donation.toFirestore();

      expect(map['donorId'], 'donor-uid-1');
      expect(map['campaignId'], 'c1');
      expect(map['amount'], 5000);
      expect(map['transactionId'], 'sim_tx_1700000000000_abc123');
      expect(map['status'], 'success');
      expect(map['donorName'], 'Jane Doe');
      expect(map.containsKey('failureCode'), isFalse);
      expect((map['createdAt'] as Timestamp).toDate().toUtc(), created);
      // id is intentionally NOT in the map — it's the doc ID.
      expect(map.containsKey('id'), isFalse);
    });

    test('failed donation includes failureCode, no transactionId', () {
      final donation = Donation(
        id: 'd2',
        donorId: 'donor-uid-1',
        campaignId: 'c1',
        amountSen: 5008,
        status: DonationStatus.failed,
        failureCode: 'cardDeclined',
        createdAt: DateTime.utc(2026, 5, 18),
      );

      final map = donation.toFirestore();

      expect(map['status'], 'failed');
      expect(map['failureCode'], 'cardDeclined');
      expect(map.containsKey('transactionId'), isFalse);
      expect(map.containsKey('donorName'), isFalse);
    });
  });
}
