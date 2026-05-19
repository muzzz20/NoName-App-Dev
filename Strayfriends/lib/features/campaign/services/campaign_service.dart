import '../models/campaign_failure.dart';
import '../models/campaign_model.dart';

// STUB: Replace with real impl when NAD-22 role check merged
class CampaignService {
  Future<void> saveCampaign(CampaignModel campaign) async {
    await Future.delayed(const Duration(seconds: 1));
    if (campaign.title.isEmpty) {
      throw const CampaignFailure('Campaign title cannot be empty.');
    }
  }

  Future<void> endCampaign(String id) async {
    await Future.delayed(const Duration(seconds: 1));
  }

  Future<List<CampaignModel>> fetchAdminCampaigns() async {
    await Future.delayed(const Duration(seconds: 1));
    return [
      CampaignModel(
        id: '1',
        title: 'Food for Feb',
        description: 'Monthly kibble resupply.',
        goalAmount: 500,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
      )
    ];
  }
}
