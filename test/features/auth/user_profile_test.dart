// Unit tests for the UserProfile model (NAD-16).
// Pure-function round-trip tests — no Firebase / network mocks needed.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strayfriends/features/auth/models/user_profile.dart';

void main() {
  group('UserProfile.toFirestore', () {
    test('serializes all fields with Timestamp for createdAt', () {
      final created = DateTime.utc(2026, 5, 14, 12, 0, 0);
      final profile = UserProfile(
        uid: 'abc123',
        email: 'test@utm.my',
        fullName: 'Test User',
        role: 'user',
        createdAt: created,
      );

      final map = profile.toFirestore();

      expect(map['email'], 'test@utm.my');
      expect(map['fullName'], 'Test User');
      expect(map['role'], 'user');
      expect(map['createdAt'], isA<Timestamp>());
      expect(
        (map['createdAt'] as Timestamp).toDate().toUtc(),
        created,
      );
      // uid is intentionally NOT in the map — it's the doc ID.
      expect(map.containsKey('uid'), isFalse);
    });
  });
}
