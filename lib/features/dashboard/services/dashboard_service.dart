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
  ///
  /// **Reads only public collections.** This method powers the public Home
  /// strip and Public Stats page (visitors, no auth), so it must never
  /// touch the private `donations` / `signups` collections. Instead it uses
  /// the Cloud-Function-maintained denormalized fields on the public
  /// `campaigns` and `activities` docs:
  /// - Funds raised  = sum(campaigns.currentAmount)
  /// - Donations     = sum(campaigns.donationCount)  (added by onDonationCreate)
  /// - Volunteers    = sum(activities.slots) − sum(activities.slotsRemaining)
  Future<DashboardStats> getStats() async {
    final reportsF = _firestore.collection('reports').count().get();
    final activeCampaignsF = _firestore
        .collection('campaigns')
        .where('status', isEqualTo: 'active')
        .count()
        .get();
    // Funds + donation count from public denormalized campaign fields.
    final campaignsAggF = _firestore
        .collection('campaigns')
        .aggregate(sum('currentAmount'), sum('donationCount'))
        .get();
    final activitiesF = _firestore.collection('activities').count().get();
    // Taken slots (= sign-ups) derived from public activities.
    final activitiesAggF = _firestore
        .collection('activities')
        .aggregate(sum('slots'), sum('slotsRemaining'))
        .get();

    final results =
        await Future.wait([reportsF, activeCampaignsF, activitiesF]);
    final campaignsAgg = await campaignsAggF;
    final activitiesAgg = await activitiesAggF;

    final slots = (activitiesAgg.getSum('slots') ?? 0).toInt();
    final slotsRemaining = (activitiesAgg.getSum('slotsRemaining') ?? 0).toInt();
    final takenSlots = (slots - slotsRemaining).clamp(0, slots);

    return DashboardStats(
      totalReports: (results[0]).count ?? 0,
      activeCampaigns: (results[1]).count ?? 0,
      totalActivities: (results[2]).count ?? 0,
      totalFundsRaisedSen: (campaignsAgg.getSum('currentAmount') ?? 0).toInt(),
      totalDonations: (campaignsAgg.getSum('donationCount') ?? 0).toInt(),
      totalSignups: takenSlots,
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
