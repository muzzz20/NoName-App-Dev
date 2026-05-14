// Unit tests for the CatReport model + enums (NAD-17).
// Pure-function tests — no Firebase / network mocks needed.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strayfriends/features/reporting/models/cat_report.dart';

void main() {
  group('CatCondition.tryParse', () {
    test('parses each storageKey case-insensitively', () {
      expect(CatCondition.tryParse('healthy'), CatCondition.healthy);
      expect(CatCondition.tryParse('INJURED'), CatCondition.injured);
      expect(CatCondition.tryParse('Sick'), CatCondition.sick);
    });
    test('returns null on unknown input', () {
      expect(CatCondition.tryParse(null), isNull);
      expect(CatCondition.tryParse('purrfect'), isNull);
    });
  });

  group('ReportStatus.tryParse', () {
    test('falls back to pending on null or unknown', () {
      expect(ReportStatus.tryParse(null), ReportStatus.pending);
      expect(ReportStatus.tryParse('mystery'), ReportStatus.pending);
    });
    test('parses each known status', () {
      for (final s in ReportStatus.values) {
        expect(ReportStatus.tryParse(s.storageKey), s);
      }
    });
  });

  group('CatReport.toFirestore', () {
    test('writes all required + optional fields', () {
      final created = DateTime.utc(2026, 5, 14, 9, 30);
      final report = CatReport(
        id: 'r1',
        userId: 'u1',
        photoUrl: 'https://example.com/photo.jpg',
        location: const GeoPoint(1.5604, 103.6373),
        locationLabel: 'KTR Block L50',
        condition: CatCondition.injured,
        description: 'Limping near library',
        status: ReportStatus.pending,
        createdAt: created,
      );

      final map = report.toFirestore();

      expect(map['userId'], 'u1');
      expect(map['photoUrl'], 'https://example.com/photo.jpg');
      expect(map['location'], isA<GeoPoint>());
      expect((map['location'] as GeoPoint).latitude, 1.5604);
      expect(map['locationLabel'], 'KTR Block L50');
      expect(map['condition'], 'injured');
      expect(map['description'], 'Limping near library');
      expect(map['status'], 'pending');
      expect((map['createdAt'] as Timestamp).toDate().toUtc(), created);
      expect(map.containsKey('id'), isFalse);
    });

    test('omits locationLabel when null', () {
      final report = CatReport(
        id: 'r2',
        userId: 'u1',
        photoUrl: 'https://example.com/p.jpg',
        location: const GeoPoint(0, 0),
        condition: CatCondition.healthy,
        description: '',
        status: ReportStatus.pending,
        createdAt: DateTime.utc(2026, 1, 1),
      );
      expect(report.toFirestore().containsKey('locationLabel'), isFalse);
    });
  });
}
