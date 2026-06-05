import 'package:cloud_firestore/cloud_firestore.dart';

/// Lifecycle for a fundraising campaign.
///
/// - `active`: currently accepting donations.
/// - `completed`: closed because the goal was reached or admin closed.
/// - `archived`: hidden from public Feed (post-completion, post-review).
enum CampaignStatus {
  active,
  completed,
  archived;

  String get label => switch (this) {
        CampaignStatus.active => 'Active',
        CampaignStatus.completed => 'Completed',
        CampaignStatus.archived => 'Archived',
      };

  /// Stored as lowercase in Firestore.
  String get storageKey => name;

  static CampaignStatus tryParse(String? value) {
    if (value == null) return CampaignStatus.active;
    return CampaignStatus.values
            .where((s) => s.storageKey == value.toLowerCase())
            .firstOrNull ??
        CampaignStatus.active;
  }
}

/// A fundraising campaign. Mirrors `campaigns/{id}` Firestore doc.
///
/// `id` is the doc ID and is never stored inside the doc itself.
/// Money amounts are stored as **integer sen** (1 RM = 100 sen) to avoid
/// floating-point rounding. UI layer formats for display (RM X.YY).
/// `currentAmountSen` is server-managed: Cloud Function
/// `onDonationCreate` increments it transactionally — clients never write
/// to it directly (rules forbid client writes to that field).
class Campaign {
  final String id;
  final String title;
  final String description;
  final int goalAmountSen;
  final int currentAmountSen;
  final String? imageUrl;
  final CampaignStatus status;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? endsAt;

  const Campaign({
    required this.id,
    required this.title,
    required this.description,
    required this.goalAmountSen,
    required this.currentAmountSen,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    this.imageUrl,
    this.endsAt,
  });

  /// Progress as a fraction in [0.0, 1.0]. Caps at 1.0 even if oversubscribed.
  double get progress {
    if (goalAmountSen <= 0) return 0;
    final raw = currentAmountSen / goalAmountSen;
    return raw > 1.0 ? 1.0 : raw;
  }

  bool get isCompleted => currentAmountSen >= goalAmountSen;

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'description': description,
        'goalAmount': goalAmountSen,
        'currentAmount': currentAmountSen,
        if (imageUrl != null) 'imageUrl': imageUrl,
        'status': status.storageKey,
        'createdBy': createdBy,
        'createdAt': Timestamp.fromDate(createdAt),
        if (endsAt != null) 'endsAt': Timestamp.fromDate(endsAt!),
      };

  factory Campaign.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Campaign doc ${doc.id} is empty');
    }
    return Campaign(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      goalAmountSen: (data['goalAmount'] as num?)?.toInt() ?? 0,
      currentAmountSen: (data['currentAmount'] as num?)?.toInt() ?? 0,
      imageUrl: data['imageUrl'] as String?,
      status: CampaignStatus.tryParse(data['status'] as String?),
      createdBy: data['createdBy'] as String? ?? '',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endsAt: (data['endsAt'] as Timestamp?)?.toDate(),
    );
  }
}
