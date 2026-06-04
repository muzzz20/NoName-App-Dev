import 'package:cloud_firestore/cloud_firestore.dart';

/// Severity assessment for a stray cat sighting.
enum CatCondition {
  healthy,
  injured,
  sick;

  String get label => switch (this) {
        CatCondition.healthy => 'Healthy',
        CatCondition.injured => 'Injured',
        CatCondition.sick => 'Sick',
      };

  /// Stored as lowercase in Firestore.
  String get storageKey => name;

  static CatCondition? tryParse(String? value) {
    if (value == null) return null;
    return CatCondition.values
        .where((c) => c.storageKey == value.toLowerCase())
        .firstOrNull;
  }
}

/// Submission status lifecycle. Default `pending` on create.
/// Admin transitions: pending → inProgress → resolved (or rejected).
enum ReportStatus {
  pending,
  inProgress,
  resolved,
  rejected;

  String get label => switch (this) {
        ReportStatus.pending => 'Pending',
        ReportStatus.inProgress => 'In progress',
        ReportStatus.resolved => 'Resolved',
        ReportStatus.rejected => 'Rejected',
      };

  String get storageKey => name;

  static ReportStatus tryParse(String? value) {
    if (value == null) return ReportStatus.pending;
    return ReportStatus.values
            .where((s) => s.storageKey == value)
            .firstOrNull ??
        ReportStatus.pending;
  }
}

/// A single cat sighting report. Mirrors `reports/{id}` Firestore doc.
///
/// `id` is the doc ID and is never stored inside the doc itself.
/// `location` is a Firestore GeoPoint (lat, lng).
/// `photoUrl` points to a Supabase Storage public URL (NAD-10).
class CatReport {
  final String id;
  final String userId;

  /// Denormalized display name of the reporter, copied from the user's
  /// profile at submit time. Lets the public Report Detail (UC-07) show
  /// "Reported by …" without reading the private `users/{uid}` doc —
  /// visitors can't read that collection. Null for legacy reports
  /// created before this field existed (resolved via fallback / backfill).
  final String? reporterName;
  final String photoUrl;
  final GeoPoint location;
  final String? locationLabel; // e.g. "Kolej Tun Razak, Block L50"
  final CatCondition condition;
  final String description;
  final ReportStatus status;
  final DateTime createdAt;

  const CatReport({
    required this.id,
    required this.userId,
    required this.photoUrl,
    required this.location,
    required this.condition,
    required this.description,
    required this.status,
    required this.createdAt,
    this.locationLabel,
    this.reporterName,
  });

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        if (reporterName != null) 'reporterName': reporterName,
        'photoUrl': photoUrl,
        'location': location,
        if (locationLabel != null) 'locationLabel': locationLabel,
        'condition': condition.storageKey,
        'description': description,
        'status': status.storageKey,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory CatReport.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) {
      throw StateError('CatReport doc ${doc.id} is empty');
    }
    return CatReport(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      reporterName: data['reporterName'] as String?,
      photoUrl: data['photoUrl'] as String? ?? '',
      location: data['location'] as GeoPoint? ?? const GeoPoint(0, 0),
      locationLabel: data['locationLabel'] as String?,
      condition: CatCondition.tryParse(data['condition'] as String?) ??
          CatCondition.healthy,
      description: data['description'] as String? ?? '',
      status: ReportStatus.tryParse(data['status'] as String?),
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
