import '../models/allocation.dart';
import '../models/campaign.dart';
import '../models/donation.dart';
import 'allocations_service.dart';
import 'campaigns_service.dart';
import 'donations_service.dart';

/// Aggregator for the public transparency report. NAD-27.
///
/// Combines a single campaign with its successful donations and
/// allocations into a [TransparencyReport] suitable for rendering on
/// the campaign detail screen's "Where the money goes" section.
///
/// **Why a separate service** instead of joining in the UI: keeps
/// the aggregation logic (unique-donor counting, total-allocated
/// summation, invariant validation) one layer below presentation, and
/// makes it trivially testable.
///
/// **Why one-shot, not stream:** the campaign + donations + allocations
/// changes are infrequent (donation cadence is human-driven); pull-to-
/// refresh is acceptable UX. A live-stream version can be added later
/// by combining the three underlying streams.
class TransparencyService {
  TransparencyService({
    CampaignsService? campaignsService,
    DonationsService? donationsService,
    AllocationsService? allocationsService,
  })  : _campaigns = campaignsService ?? CampaignsService(),
        _donations = donationsService ?? DonationsService(),
        _allocations = allocationsService ?? AllocationsService();

  final CampaignsService _campaigns;
  final DonationsService _donations;
  final AllocationsService _allocations;

  /// Fetch the transparency snapshot for one campaign.
  ///
  /// `donationLimit` / `allocationLimit` cap the lists we pull —
  /// totals + counts remain accurate up to those caps. Sprint 4 will
  /// replace this with a server-side aggregator if a campaign ever
  /// crosses these limits.
  Future<TransparencyReport> getReport({
    required String campaignId,
    int donationLimit = 500,
    int allocationLimit = 200,
  }) async {
    final campaign = await _campaigns.getCampaign(campaignId);
    if (campaign == null) {
      throw const TransparencyFailure('Campaign not found.');
    }

    final donations = await _donations
        .watchDonationsForCampaign(
          campaignId: campaignId,
          limit: donationLimit,
          successOnly: true,
        )
        .first;

    final allocations = await _allocations
        .watchAllocationsForCampaign(
          campaignId: campaignId,
          limit: allocationLimit,
        )
        .first;

    final uniqueDonors = donations.map((d) => d.donorId).toSet();
    final totalAllocatedSen =
        allocations.fold<int>(0, (sum, a) => sum + a.amountSen);

    return TransparencyReport(
      campaign: campaign,
      donorCount: uniqueDonors.length,
      totalAllocatedSen: totalAllocatedSen,
      allocations: allocations,
      recentSuccessfulDonations: donations.take(10).toList(),
    );
  }
}

/// Snapshot of a campaign's fundraising state for the public
/// transparency view. Per NAD-27 AC: "total raised, donor count,
/// allocations array, sum of allocations never exceeds currentAmount."
class TransparencyReport {
  /// The campaign itself — `campaign.currentAmountSen` IS the total raised.
  final Campaign campaign;

  /// Number of unique donors who made a successful donation.
  /// Computed by de-duplicating `donorId` across the fetched donations.
  final int donorCount;

  /// Sum of all allocation amounts. Sprint 2 invariant:
  /// `totalAllocatedSen <= campaign.goalAmountSen`. Cloud Function
  /// `onAllocationCreate` is the authoritative enforcer; this field
  /// is read-only display data.
  final int totalAllocatedSen;

  /// All allocations for this campaign, newest first (up to limit).
  final List<Allocation> allocations;

  /// Most recent successful donations, newest first (cap 10). Used for
  /// the "Recent supporters" section on the transparency page.
  final List<Donation> recentSuccessfulDonations;

  const TransparencyReport({
    required this.campaign,
    required this.donorCount,
    required this.totalAllocatedSen,
    required this.allocations,
    required this.recentSuccessfulDonations,
  });

  /// Remaining unallocated balance in sen. Negative is impossible if
  /// the Cloud Function invariant holds, but defensive math: clamped
  /// at 0 in case a stale snapshot is rendered briefly.
  int get unallocatedSen {
    final raw = campaign.goalAmountSen - totalAllocatedSen;
    return raw < 0 ? 0 : raw;
  }

  /// True when the allocation invariant has been violated. Should
  /// always be false in a healthy system — exposed only so the UI can
  /// surface a visible error banner if rendering catches a transient
  /// stale state.
  bool get invariantViolated =>
      totalAllocatedSen > campaign.goalAmountSen;
}

class TransparencyFailure implements Exception {
  final String message;
  const TransparencyFailure(this.message);

  @override
  String toString() => message;
}
