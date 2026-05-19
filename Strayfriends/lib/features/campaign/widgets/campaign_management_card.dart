import 'package:flutter/material.dart';
import '../models/campaign_model.dart';
import '../../../core/theme/app_colors.dart';

class CampaignManagementCard extends StatelessWidget {
  final CampaignModel campaign;
  final VoidCallback onEdit;
  final VoidCallback onEndEarly;

  /// Card view for a campaign in the admin list.
  const CampaignManagementCard({
    super.key,
    required this.campaign,
    required this.onEdit,
    required this.onEndEarly,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    campaign.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                if (!campaign.isActive)
                  const Chip(label: Text('Closed')),
              ],
            ),
            const SizedBox(height: 8),
            Text('Goal: RM ${campaign.goalAmount.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (campaign.isActive)
                  TextButton(
                    onPressed: onEndEarly,
                    child: const Text('End Early', style: TextStyle(color: AppColors.error)),
                  ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: onEdit,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: const Text('Edit', style: TextStyle(color: AppColors.onPrimary)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
