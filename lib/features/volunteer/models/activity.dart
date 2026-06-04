import 'package:cloud_firestore/cloud_firestore.dart';

/// Lifecycle for a volunteer activity. NAD-42.
enum ActivityStatus {
  upcoming,
  completed,
  cancelled;

  String get label => switch (this) {
        ActivityStatus.upcoming => 'Upcoming',
        ActivityStatus.completed => 'Completed',
        ActivityStatus.cancelled => 'Cancelled',
      };

  String get storageKey => name;

  static ActivityStatus tryParse(String? value) {
    if (value == null) return ActivityStatus.upcoming;
    return ActivityStatus.values
            .where((s) => s.storageKey == value.toLowerCase())
            .firstOrNull ??
        ActivityStatus.upcoming;
  }
}

/// A volunteer activity. Mirrors `activities/{id}` Firestore doc.
///
/// `slotsRemaining` decrements atomically on each sign-up (NAD-43) via a
/// client-side Firestore transaction in SignupsService — when it hits 0
/// the activity is full and further sign-ups are rejected.
class Activity {
  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime dateTime;
  final int slots;
  final int slotsRemaining;
  final String? imageUrl;
  final String createdBy;
  final ActivityStatus status;
  final DateTime createdAt;

  const Activity({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.dateTime,
    required this.slots,
    required this.slotsRemaining,
    required this.createdBy,
    required this.status,
    required this.createdAt,
    this.imageUrl,
  });

  bool get isFull => slotsRemaining <= 0;
  bool get isPast => dateTime.isBefore(DateTime.now());
  int get volunteerCount => slots - slotsRemaining;

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'description': description,
        'location': location,
        'dateTime': Timestamp.fromDate(dateTime),
        'slots': slots,
        'slotsRemaining': slotsRemaining,
        if (imageUrl != null) 'imageUrl': imageUrl,
        'createdBy': createdBy,
        'status': status.storageKey,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory Activity.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Activity doc ${doc.id} is empty');
    }
    return Activity(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      location: data['location'] as String? ?? '',
      dateTime: (data['dateTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      slots: (data['slots'] as num?)?.toInt() ?? 0,
      slotsRemaining: (data['slotsRemaining'] as num?)?.toInt() ?? 0,
      imageUrl: data['imageUrl'] as String?,
      createdBy: data['createdBy'] as String? ?? '',
      status: ActivityStatus.tryParse(data['status'] as String?),
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
