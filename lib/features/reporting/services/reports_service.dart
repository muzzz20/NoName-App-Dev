import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cat_report.dart';

/// Firestore data layer for `reports` collection.
///
/// Per NAD-9 AC:
/// - reports/{id} doc has userId / photoUrl / geopoint / condition /
///   description / createdAt
/// - List newest first
/// - Filter by userId (for "My Reports")
/// - Security rules in firestore.rules
class ReportsService {
  ReportsService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _reports =>
      _firestore.collection('reports');

  /// Create a new report. Returns the created [CatReport] with assigned id.
  ///
  /// Callers should NOT pre-set an id — Firestore auto-generates one.
  Future<CatReport> createReport({
    required String userId,
    required String photoUrl,
    required GeoPoint location,
    required CatCondition condition,
    required String description,
    String? locationLabel,
    String? reporterName,
  }) async {
    final docRef = _reports.doc();
    final report = CatReport(
      id: docRef.id,
      userId: userId,
      reporterName: reporterName,
      photoUrl: photoUrl,
      location: location,
      locationLabel: locationLabel,
      condition: condition,
      description: description,
      status: ReportStatus.pending,
      createdAt: DateTime.now().toUtc(),
    );
    await docRef.set(report.toFirestore());
    return report;
  }

  /// Stream of ALL reports, newest first. Powers the public Feed (NAD-12).
  Stream<List<CatReport>> watchAllReports({int limit = 50}) {
    return _reports
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(CatReport.fromFirestore).toList());
  }

  /// Stream of reports filtered by a single userId, newest first.
  /// Powers "My Reports" (NAD-14).
  Stream<List<CatReport>> watchUserReports({
    required String userId,
    int limit = 50,
  }) {
    return _reports
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(CatReport.fromFirestore).toList());
  }

  /// One-shot fetch of a single report by id. Powers the Detail screen
  /// (NAD-13) when a deep link arrives without an existing stream.
  Future<CatReport?> getReport(String id) async {
    final snap = await _reports.doc(id).get();
    if (!snap.exists) return null;
    return CatReport.fromFirestore(snap);
  }

  /// Admin-only — update status (e.g. pending → inProgress → resolved).
  /// Rejected via Firestore rules for non-admins.
  Future<void> updateStatus({
    required String reportId,
    required ReportStatus status,
  }) async {
    await _reports.doc(reportId).update({'status': status.storageKey});
  }
}
