import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../models/campaign.dart';
import '../services/campaigns_service.dart';
import '../widgets/campaign_card.dart';

class CampaignsListScreen extends StatefulWidget {
  const CampaignsListScreen({super.key});

  @override
  State<CampaignsListScreen> createState() => _CampaignsListScreenState();
}

class _CampaignsListScreenState extends State<CampaignsListScreen> {
  final _campaignsService = CampaignsService();
  String _filter = 'All'; // All, Active, Completed

  // Dummy campaigns removed, now reading from Firestore!


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Campaign>>(
        stream: _campaignsService.watchAllCampaigns(),
        builder: (context, snapshot) {
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                title: Text('Fundraising', style: AppText.titleSm),
                pinned: true,
                flexibleSpace: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      color: AppColors.surface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.history),
                    onPressed: () => context.push('/my-donations'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_box_outlined),
                    onPressed: () => context.push('/admin-campaign'),
                  ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(60),
                  child: Padding(
                    padding: AppSpacing.horizontalPagePadding.copyWith(bottom: AppSpacing.stackMd),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['All', 'Active', 'Completed'].map((filter) {
                          final isSelected = _filter == filter;
                          return Padding(
                            padding: const EdgeInsets.only(right: AppSpacing.stackSm),
                            child: ChoiceChip(
                              label: Text(filter),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) setState(() => _filter = filter);
                              },
                              selectedColor: AppColors.primaryContainer,
                              labelStyle: AppText.labelCaps.copyWith(
                                color: isSelected ? AppColors.onPrimaryContainer : AppColors.onSurfaceVariant,
                              ),
                              backgroundColor: AppColors.secondaryContainer,
                              side: BorderSide.none,
                              shape: const RoundedRectangleBorder(
                                borderRadius: AppRadius.pillRadius,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
              _buildContent(context, snapshot),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, AsyncSnapshot<List<Campaign>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (snapshot.hasError) {
      return SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.stackLg),
            child: Text(
              'Error loading campaigns: ${snapshot.error}',
              style: AppText.bodyBase.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final campaigns = snapshot.data ?? [];
    final filteredCampaigns = campaigns.where((c) {
      if (_filter == 'All') return true;
      return c.status.name.toLowerCase() == _filter.toLowerCase();
    }).toList();

    if (filteredCampaigns.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.pets, size: 64, color: AppColors.outlineVariant),
              const SizedBox(height: AppSpacing.stackMd),
              Text(
                'No $_filter campaigns right now.',
                style: AppText.bodyBase.copyWith(color: AppColors.secondary),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: AppSpacing.pagePadding,
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final campaign = filteredCampaigns[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.stackMd),
              child: CampaignCard(
                campaign: campaign,
                onTap: () => context.push('/campaign/${campaign.id}'),
              ),
            );
          },
          childCount: filteredCampaigns.length,
        ),
      ),
    );
  }
}
