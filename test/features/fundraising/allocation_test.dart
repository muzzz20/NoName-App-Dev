// Unit tests for the Allocation model (NAD-27 / NAD-34).
// Pure-function tests — no Firebase / network mocks needed.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strayfriends/features/fundraising/models/allocation.dart';

void main() {
  group('Allocation.toFirestore', () {
    test('serializes all fields including optional evidenceUrl', () {
      final created = DateTime.utc(2026, 5, 18, 10, 0);
      final allocation = Allocation(
        id: 'a1',
        campaignId: 'c1',
        amountSen: 35000, // RM 350.00
        purpose: 'Vet bill — cat at Block L50',
        evidenceUrl: 'https://supabase.example/receipts/a1.jpg',
        createdBy: 'admin-uid-1',
        createdAt: created,
      );

      final map = allocation.toFirestore();

      expect(map['campaignId'], 'c1');
      expect(map['amount'], 35000);
      expect(map['purpose'], 'Vet bill — cat at Block L50');
      expect(map['evidenceUrl'], 'https://supabase.example/receipts/a1.jpg');
      expect(map['createdBy'], 'admin-uid-1');
      expect((map['createdAt'] as Timestamp).toDate().toUtc(), created);
      // id is intentionally NOT in the map — it's the doc ID.
      expect(map.containsKey('id'), isFalse);
    });

    test('omits evidenceUrl when null', () {
      final allocation = Allocation(
        id: 'a2',
        campaignId: 'c1',
        amountSen: 10000,
        purpose: 'Food + litter for shelter',
        createdBy: 'admin-uid-1',
        createdAt: DateTime.utc(2026, 1, 1),
      );
      expect(allocation.toFirestore().containsKey('evidenceUrl'), isFalse);
    });
  });
}
