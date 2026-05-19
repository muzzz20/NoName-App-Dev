import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../models/campaign.dart';
import '../services/campaigns_service.dart';

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
              child: _buildCampaignCard(context, campaign),
            );
          },
          childCount: filteredCampaigns.length,
        ),
      ),
    );
  }

  Widget _buildCampaignCard(BuildContext context, Campaign campaign) {
    final isCompleted = campaign.status == CampaignStatus.completed;

    return GestureDetector(
      onTap: () => context.push('/campaign/${campaign.id}'),
      child: Opacity(
        opacity: isCompleted ? 0.6 : 1.0,
        child: Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
                child: ColorFiltered(
                  colorFilter: isCompleted
                      ? const ColorFilter.matrix([
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0, 0, 0, 1, 0,
                        ])
                      : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                  child: Image.network(
                    campaign.imageUrl ?? '',
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 180,
                      width: double.infinity,
                      color: AppColors.surfaceVariant,
                      child: const Icon(Icons.pets, size: 48, color: AppColors.outline),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.stackMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            campaign.title,
                            style: AppText.titleSm,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.stackSm,
                            vertical: AppSpacing.stackXs,
                          ),
                          decoration: BoxDecoration(
                            color: isCompleted ? AppColors.surfaceVariant : AppColors.primaryContainer,
                            borderRadius: AppRadius.pillRadius,
                          ),
                          child: Text(
                            campaign.status.name.toUpperCase(),
                            style: AppText.labelCaps.copyWith(
                              color: isCompleted ? AppColors.onSurfaceVariant : AppColors.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.stackSm),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      child: LinearProgressIndicator(
                        value: campaign.progress,
                        backgroundColor: AppColors.surfaceVariant,
                        color: AppColors.primary,
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.stackSm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'RM ${(campaign.currentAmountSen / 100).toStringAsFixed(0)} raised',
                          style: AppText.bodySm.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Goal: RM ${(campaign.goalAmountSen / 100).toStringAsFixed(0)}',
                          style: AppText.bodySm.copyWith(color: AppColors.secondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
