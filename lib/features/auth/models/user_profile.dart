import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore-backed user profile. Mirrors a `users/{uid}` document.
///
/// `uid` is the Firebase Auth UID and the doc ID — never stored as a field
/// inside the doc itself (avoid duplication).
class UserProfile {
  final String uid;
  final String email;
  final String fullName;
  final String role; // 'user' | 'admin' | 'ngo' — see NAD-22 for admin/ngo
  final String? photoUrl; // avatar (UC-04); null = show initials
  final DateTime createdAt;

  const UserProfile({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.role,
    required this.createdAt,
    this.photoUrl,
  });

  Map<String, dynamic> toFirestore() => {
        'email': email,
        'fullName': fullName,
        'role': role,
        if (photoUrl != null) 'photoUrl': photoUrl,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory UserProfile.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError('User profile doc ${doc.id} is empty');
    }
    return UserProfile(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      fullName: data['fullName'] as String? ?? '',
      role: data['role'] as String? ?? 'user',
      photoUrl: data['photoUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
