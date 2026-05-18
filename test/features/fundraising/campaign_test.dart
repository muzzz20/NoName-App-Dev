// Unit tests for the Campaign model + enums (NAD-25 / NAD-34).
// Pure-function tests — no Firebase / network mocks needed.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strayfriends/features/fundraising/models/campaign.dart';

void main() {
  group('CampaignStatus.tryParse', () {
    test('parses each storageKey case-insensitively', () {
      expect(CampaignStatus.tryParse('active'), CampaignStatus.active);
      expect(CampaignStatus.tryParse('COMPLETED'), CampaignStatus.completed);
      expect(CampaignStatus.tryParse('Archived'), CampaignStatus.archived);
    });
    test('falls back to active on null or unknown', () {
      expect(CampaignStatus.tryParse(null), CampaignStatus.active);
      expect(CampaignStatus.tryParse('mystery'), CampaignStatus.active);
    });
  });

  group('Campaign.toFirestore', () {
    test('serializes all fields including optional endsAt + imageUrl', () {
      final created = DateTime.utc(2026, 5, 18, 9, 0);
      final endsAt = DateTime.utc(2026, 6, 18, 9, 0);
      final campaign = Campaign(
        id: 'c1',
        title: 'Vet bills for KTR cats',
        description: 'Help us cover vaccinations for 12 stray cats.',
        goalAmountSen: 100000, // RM 1000.00
        currentAmountSen: 25000, // RM 250.00 raised
        imageUrl: 'https://supabase.example/heros/c1.jpg',
        status: CampaignStatus.active,
        createdBy: 'admin-uid-1',
        createdAt: created,
        endsAt: endsAt,
      );

      final map = campaign.toFirestore();

      expect(map['title'], 'Vet bills for KTR cats');
      expect(map['description'], 'Help us cover vaccinations for 12 stray cats.');
      expect(map['goalAmount'], 100000);
      expect(map['currentAmount'], 25000);
      expect(map['imageUrl'], 'https://supabase.example/heros/c1.jpg');
      expect(map['status'], 'active');
      expect(map['createdBy'], 'admin-uid-1');
      expect((map['createdAt'] as Timestamp).toDate().toUtc(), created);
      expect((map['endsAt'] as Timestamp).toDate().toUtc(), endsAt);
      // id is intentionally NOT in the map — it's the doc ID.
      expect(map.containsKey('id'), isFalse);
    });

    test('omits optional fields when null', () {
      final campaign = Campaign(
        id: 'c2',
        title: 'Generic',
        description: '',
        goalAmountSen: 10000,
        currentAmountSen: 0,
        status: CampaignStatus.active,
        createdBy: 'admin-uid-1',
        createdAt: DateTime.utc(2026, 1, 1),
      );
      final map = campaign.toFirestore();
      expect(map.containsKey('imageUrl'), isFalse);
      expect(map.containsKey('endsAt'), isFalse);
    });
  });

  group('Campaign progress + isCompleted', () {
    Campaign mk({required int goal, required int current}) => Campaign(
          id: 'x',
          title: 't',
          description: 'd',
          goalAmountSen: goal,
          currentAmountSen: current,
          status: CampaignStatus.active,
          createdBy: 'u',
          createdAt: DateTime.utc(2026, 1, 1),
        );

    test('progress is 0 when nothing raised', () {
      expect(mk(goal: 10000, current: 0).progress, 0);
    });
    test('progress is the ratio when partway', () {
      expect(mk(goal: 10000, current: 2500).progress, 0.25);
    });
    test('progress caps at 1.0 when oversubscribed', () {
      expect(mk(goal: 10000, current: 15000).progress, 1.0);
    });
    test('progress is 0 when goal is zero (defensive)', () {
      expect(mk(goal: 0, current: 100).progress, 0);
    });
    test('isCompleted true when current >= goal', () {
      expect(mk(goal: 1000, current: 999).isCompleted, isFalse);
      expect(mk(goal: 1000, current: 1000).isCompleted, isTrue);
      expect(mk(goal: 1000, current: 1500).isCompleted, isTrue);
    });
  });
}
