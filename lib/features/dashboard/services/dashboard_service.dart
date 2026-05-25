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
  final int totalCampaigns;
  final int totalFundsRaisedSen;
  final int totalDonations;
  final int totalActivities;
  final int totalSignups;
  final int totalUsers;

  const DashboardStats({
    required this.totalReports,
    required this.activeCampaigns,
    required this.totalFundsRaisedSen,
    required this.totalDonations,
    required this.totalActivities,
    required this.totalSignups,
    this.totalCampaigns = 0,
    this.totalUsers = 0,
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
    final campaigns = _firestore.collection('campaigns');
    final activities = _firestore.collection('activities');

    // NOTE: each sum() is its OWN aggregate query. Combining two sum()s on
    // different fields in a single .aggregate() call requires a composite
    // index (currentAmount+donationCount / slots+slotsRemaining); splitting
    // them keeps each on Firestore's automatic single-field index, so no
    // composite index — and no deploy — is needed. All run in parallel.
    final reportsF = _firestore.collection('reports').count().get();
    final activeCampaignsF =
        campaigns.where('status', isEqualTo: 'active').count().get();
    final fundsF = campaigns.aggregate(sum('currentAmount')).get();
    final donationsF = campaigns.aggregate(sum('donationCount')).get();
    final activitiesF = activities.count().get();
    final slotsF = activities.aggregate(sum('slots')).get();
    final slotsRemainingF = activities.aggregate(sum('slotsRemaining')).get();

    final reports = await reportsF;
    final activeCampaigns = await activeCampaignsF;
    final funds = await fundsF;
    final donations = await donationsF;
    final activitiesCount = await activitiesF;
    final slotsAgg = await slotsF;
    final slotsRemainingAgg = await slotsRemainingF;

    final slots = (slotsAgg.getSum('slots') ?? 0).toInt();
    final slotsRemaining =
        (slotsRemainingAgg.getSum('slotsRemaining') ?? 0).toInt();
    final takenSlots = (slots - slotsRemaining).clamp(0, slots);

    return DashboardStats(
      totalReports: reports.count ?? 0,
      activeCampaigns: activeCampaigns.count ?? 0,
      totalActivities: activitiesCount.count ?? 0,
      totalFundsRaisedSen: (funds.getSum('currentAmount') ?? 0).toInt(),
      totalDonations: (donations.getSum('donationCount') ?? 0).toInt(),
      totalSignups: takenSlots,
    );
  }

  /// Admin/NGO dashboard totals — overall counts across the whole system,
  /// including `totalCampaigns` (ALL statuses) and `totalUsers` (registered
  /// accounts). The users count needs auth (`users` read = signed-in), so this
  /// is dashboard-only and must NOT power the public Home/Public-Stats views —
  /// use [getStats] there. Each query runs on Firestore's automatic
  /// single-field index (no composite index, no deploy).
  Future<DashboardStats> getDashboardStats() async {
    final campaigns = _firestore.collection('campaigns');
    final reportsF = _firestore.collection('reports').count().get();
    final campaignsF = campaigns.count().get();
    final fundsF = campaigns.aggregate(sum('currentAmount')).get();
    final donationsF = campaigns.aggregate(sum('donationCount')).get();
    final activitiesF = _firestore.collection('activities').count().get();
    final usersF = _firestore.collection('users').count().get();

    final reports = await reportsF;
    final allCampaigns = await campaignsF;
    final funds = await fundsF;
    final donations = await donationsF;
    final activities = await activitiesF;
    final users = await usersF;

    return DashboardStats(
      totalReports: reports.count ?? 0,
      activeCampaigns: 0, // not shown on the dashboard
      totalCampaigns: allCampaigns.count ?? 0,
      totalFundsRaisedSen: (funds.getSum('currentAmount') ?? 0).toInt(),
      totalDonations: (donations.getSum('donationCount') ?? 0).toInt(),
      totalActivities: activities.count ?? 0,
      totalSignups: 0, // replaced by totalUsers on the dashboard
      totalUsers: users.count ?? 0,
    );
  }

  /// 30-day donation trend, bucketed by day (oldest → newest). Reads
  /// successful donations from the last 30 days and buckets client-side.
  Future<List<DailyDonation>> getDonationTrend() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 29));
    // Range on createdAt only (single-field index). Filtering status server-
    // side too would need a (status, createdAt) composite index — instead we
    // filter status client-side below; the 30-day window keeps the set small.
    final snap = await _firestore
        .collection('donations')
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
      if (data['status'] != 'success') continue; // count successful only
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
