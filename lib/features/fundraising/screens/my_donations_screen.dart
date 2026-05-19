import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../models/donation.dart';

import '../services/donations_service.dart';
import '../services/campaigns_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyDonationsScreen extends StatefulWidget {
  const MyDonationsScreen({super.key});

  @override
  State<MyDonationsScreen> createState() => _MyDonationsScreenState();
}

class _MyDonationsScreenState extends State<MyDonationsScreen> {
  final _donationsService = DonationsService();
  final _campaignsService = CampaignsService();
  final Map<String, String> _campaignNames = {};

  Future<String> _getCampaignName(String campaignId) async {
    if (_campaignNames.containsKey(campaignId)) {
      return _campaignNames[campaignId]!;
    }
    final campaign = await _campaignsService.getCampaign(campaignId);
    final title = campaign?.title ?? 'Unknown Campaign';
    _campaignNames[campaignId] = title;
    return title;
  }

  @override
  Widget build(BuildContext context) {
    final donorId = FirebaseAuth.instance.currentUser?.uid ?? 'sim_user_123';

    return StreamBuilder<List<Donation>>(
      stream: _donationsService.watchDonationsByDonor(donorId: donorId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final donations = snapshot.data ?? [];
        final totalDonated = donations
            .where((d) => d.status == DonationStatus.success)
            .fold(0.0, (sum, d) => sum + (d.amountSen / 100));

        return Scaffold(
          appBar: AppBar(
            title: const Text('My Impact'),
            flexibleSpace: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  color: AppColors.surface.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
          body: donations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.favorite_border, size: 64, color: AppColors.outlineVariant),
                      const SizedBox(height: AppSpacing.stackMd),
                      Text(
                        'You haven\'t made any donations yet.\nEvery little bit helps!',
                        textAlign: TextAlign.center,
                        style: AppText.bodyBase.copyWith(color: AppColors.secondary),
                      ),
                      const SizedBox(height: AppSpacing.stackLg),
                      ElevatedButton(
                        onPressed: () => context.push('/home'),
                        child: const Text('Browse Campaigns'),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: AppSpacing.pagePadding,
                  children: [
                    // Total Impact Card
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.stackLg),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryContainer,
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                      ),
                      child: Column(
                        children: [
                          Text('Total Donated', style: AppText.labelCaps),
                          const SizedBox(height: AppSpacing.stackSm),
                          Text(
                            'RM ${totalDonated.toStringAsFixed(0)}',
                            style: AppText.displayLg.copyWith(color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.stackLg),
                    Text('Donation History', style: AppText.titleSm),
                    const SizedBox(height: AppSpacing.stackMd),
                    ...donations.map((donation) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.stackMd),
                      child: FutureBuilder<String>(
                        future: _getCampaignName(donation.campaignId),
                        builder: (context, nameSnapshot) {
                          final campaignName = nameSnapshot.data ?? 'Loading...';
                          return GestureDetector(
                            onTap: () {
                              if (donation.status == DonationStatus.success) {
                                context.push('/receipt', extra: {
                                  'campaignName': campaignName,
                                  'amount': donation.amountSen / 100,
                                  'transactionId': donation.transactionId,
                                  'date': donation.createdAt,
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.stackMd),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLowest,
                                border: Border.all(color: AppColors.cardBorder),
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: donation.status == DonationStatus.success
                                          ? AppColors.primaryContainer
                                          : AppColors.errorContainer,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      donation.status == DonationStatus.success ? Icons.favorite : Icons.error_outline,
                                      color: donation.status == DonationStatus.success
                                          ? AppColors.onPrimaryContainer
                                          : AppColors.onErrorContainer,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.stackMd),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          campaignName,
                                          style: AppText.bodyBase.copyWith(fontWeight: FontWeight.w600),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${donation.createdAt.day}/${donation.createdAt.month}/${donation.createdAt.year}',
                                          style: AppText.bodySm.copyWith(color: AppColors.secondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'RM ${(donation.amountSen / 100).toStringAsFixed(0)}',
                                        style: AppText.titleSm,
                                      ),
                                      if (donation.status != DonationStatus.success)
                                        Text(
                                          'Failed',
                                          style: AppText.labelCaps.copyWith(color: AppColors.error),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    )),
                  ],
                ),
        );
      },
    );
  }
}
