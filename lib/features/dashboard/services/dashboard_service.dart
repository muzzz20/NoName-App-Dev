import 'package:cloud_firestore/cloud_firestore.dart';

/// Aggregated cross-module metrics for the dashboards. NAD-50.
///
/// Computed on-read using Firestore **aggregation queries** (count/sum) —
/// these run server-side and bill as a tiny number of reads, so latency
/// stays well under the 2s AC even as data grows. No precomputed stats
/// doc or scheduled function needed; numbers are always live.
class DashboardStats {
  final int totalReports;
  final int activeCampaigns;
  final int totalFundsRaisedSen;
  final int totalDonations;
  final int totalActivities;
  final int totalSignups;

  const DashboardStats({
    required this.totalReports,
    required this.activeCampaigns,
    required this.totalFundsRaisedSen,
    required this.totalDonations,
    required this.totalActivities,
    required this.totalSignups,
  });
}

/// One day's bucket in the 30-day donation trend.
class DailyDonation {
  final DateTime day;
  final int totalSen;
  const DailyDonation(this.day, this.totalSen);
}

class DashboardService {
  DashboardService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Compute all KPI metrics in parallel. Latency is dominated by the
  /// slowest aggregation query (~hundreds of ms).
  Future<DashboardStats> getStats() async {
    final reportsF = _firestore.collection('reports').count().get();
    final activeCampaignsF = _firestore
        .collection('campaigns')
        .where('status', isEqualTo: 'active')
        .count()
        .get();
    final donationsF = _firestore
        .collection('donations')
        .where('status', isEqualTo: 'success')
        .count()
        .get();
    final fundsF = _firestore
        .collection('donations')
        .where('status', isEqualTo: 'success')
        .aggregate(sum('amount'))
        .get();
    final activitiesF = _firestore.collection('activities').count().get();
    final signupsF = _firestore.collection('signups').count().get();

    final results = await Future.wait([
      reportsF,
      activeCampaignsF,
      donationsF,
      activitiesF,
      signupsF,
    ]);
    final funds = await fundsF;

    return DashboardStats(
      totalReports: (results[0]).count ?? 0,
      activeCampaigns: (results[1]).count ?? 0,
      totalDonations: (results[2]).count ?? 0,
      totalActivities: (results[3]).count ?? 0,
      totalSignups: (results[4]).count ?? 0,
      totalFundsRaisedSen: (funds.getSum('amount') ?? 0).toInt(),
    );
  }

  /// 30-day donation trend, bucketed by day (oldest → newest). Reads
  /// successful donations from the last 30 days and buckets client-side.
  Future<List<DailyDonation>> getDonationTrend() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 29));
    final snap = await _firestore
        .collection('donations')
        .where('status', isEqualTo: 'success')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .get();

    // Initialize 30 day-buckets at 0.
    final buckets = <DateTime, int>{};
    for (var i = 0; i < 30; i++) {
      final d = start.add(Duration(days: i));
      buckets[DateTime(d.year, d.month, d.day)] = 0;
    }
    for (final doc in snap.docs) {
      final data = doc.data();
      final ts = (data['createdAt'] as Timestamp?)?.toDate();
      final amount = (data['amount'] as num?)?.toInt() ?? 0;
      if (ts == null) continue;
      final key = DateTime(ts.year, ts.month, ts.day);
      if (buckets.containsKey(key)) buckets[key] = buckets[key]! + amount;
    }
    final days = buckets.keys.toList()..sort();
    return [for (final d in days) DailyDonation(d, buckets[d]!)];
  }
}
