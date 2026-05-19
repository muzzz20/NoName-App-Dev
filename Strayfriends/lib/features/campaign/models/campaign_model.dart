class AllocationEntry {
  final String label;
  final double amount;

  const AllocationEntry({required this.label, required this.amount});
}

class CampaignModel {
  final String id;
  final String title;
  final String description;
  final double goalAmount;
  final DateTime startDate;
  final DateTime endDate;
  final String? coverImageUrl;
  final bool isActive;
  final List<AllocationEntry> allocations;

  /// Holds the state for a single campaign.
  const CampaignModel({
    required this.id,
    required this.title,
    required this.description,
    required this.goalAmount,
    required this.startDate,
    required this.endDate,
    this.coverImageUrl,
    this.isActive = true,
    this.allocations = const [],
  });
}
