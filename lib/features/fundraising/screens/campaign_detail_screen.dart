import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../services/transparency_service.dart';
import '../../auth/services/auth_service.dart';
import '../models/campaign.dart';

class CampaignDetailScreen extends StatefulWidget {
  final String campaignId;

  const CampaignDetailScreen({super.key, required this.campaignId});

  @override
  State<CampaignDetailScreen> createState() => _CampaignDetailScreenState();
}

class _CampaignDetailScreenState extends State<CampaignDetailScreen> {
  final _transparencyService = TransparencyService();
  late Future<TransparencyReport> _reportFuture;
  final _authService = AuthService();
  final Map<String, String> _creatorNames = {};

  Future<String> _getCreatorName(String uid) async {
    if (uid.isEmpty) return 'Strayfriends NGO';
    if (_creatorNames.containsKey(uid)) {
      return _creatorNames[uid]!;
    }
    if (uid == 'ngo1' || uid == 'ngo2' || uid == 'admin' || uid == 'admin_user_123') {
      return 'Strayfriends NGO';
    }
    if (uid == 'sim_user_123') {
      return 'Strayfriends Supporter';
    }
    try {
      final profile = await _authService.loadProfile(uid: uid);
      final name = profile?.fullName ?? 'Strayfriends NGO';
      _creatorNames[uid] = name;
      return name;
    } catch (_) {
      return 'Strayfriends NGO';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  void _loadReport() {
    _reportFuture = _transparencyService.getReport(campaignId: widget.campaignId);
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _loadReport();
    });
    await _reportFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<TransparencyReport>(
        future: _reportFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: AppSpacing.stackMd),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.stackLg),
                    child: Text(
                      'Failed to load campaign details: ${snapshot.error}',
                      style: AppText.bodyBase,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.stackLg),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          final report = snapshot.data!;
          final campaign = report.campaign;
          final donorCount = report.donorCount;
          final allocations = report.allocations;

          return Stack(
            children: [
              RefreshIndicator(
                onRefresh: _handleRefresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 100), // Space for sticky CTA
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          Image.network(
                            campaign.imageUrl ?? '',
                            width: double.infinity,
                            height: 300,
                            fit: BoxFit.contain, // BR-004 fix
                            alignment: Alignment.topCenter,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: double.infinity,
                              height: 300,
                              color: AppColors.surfaceVariant,
                              child: const Icon(Icons.pets, size: 64, color: AppColors.outline),
                            ),
                          ),
                          SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.stackMd),
                              child: ClipOval(
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: Container(
                                    color: AppColors.surface.withValues(alpha: 0.6),
                                    child: IconButton(
                                      icon: const Icon(Icons.arrow_back),
                                      color: AppColors.onSurface,
                                      onPressed: () => Navigator.pop(context), // BR-005 fix
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: AppSpacing.pagePadding,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    campaign.title,
                                    style: AppText.headlineMd,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.stackMd,
                                    vertical: AppSpacing.stackXs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryContainer,
                                    borderRadius: AppRadius.pillRadius,
                                  ),
                                  child: Text(
                                    campaign.status.name.toUpperCase(),
                                    style: AppText.labelCaps.copyWith(color: AppColors.onPrimaryContainer),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.stackXs),
                             FutureBuilder<String>(
                               future: _getCreatorName(campaign.createdBy),
                               builder: (context, nameSnapshot) {
                                 return Text(
                                   'Organized by ${nameSnapshot.data ?? '...'}',
                                   style: AppText.bodySm.copyWith(color: AppColors.secondary),
                                 );
                               },
                             ),
                            const SizedBox(height: AppSpacing.stackLg),
                            
                            // Progress Section
                            ClipRRect(
                              borderRadius: BorderRadius.circular(AppRadius.full),
                              child: LinearProgressIndicator(
                                value: campaign.progress,
                                backgroundColor: AppColors.surfaceVariant,
                                color: AppColors.primary,
                                minHeight: 12,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.stackSm),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'RM ${(campaign.currentAmountSen / 100).toStringAsFixed(0)}',
                                  style: AppText.titleSm.copyWith(color: AppColors.primary),
                                ),
                                Text(
                                  'RM ${(campaign.goalAmountSen / 100).toStringAsFixed(0)} Goal',
                                  style: AppText.bodyBase.copyWith(color: AppColors.secondary),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.stackMd),
                            
                            // Bento Grid Stats
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(AppSpacing.stackMd),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondaryContainer,
                                      borderRadius: BorderRadius.circular(AppRadius.md),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          '$donorCount',
                                          style: AppText.headlineMd,
                                        ),
                                        Text('Donors', style: AppText.labelCaps),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.stackMd),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(AppSpacing.stackMd),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondaryContainer,
                                      borderRadius: BorderRadius.circular(AppRadius.md),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          '${campaign.endsAt?.difference(DateTime.now()).inDays ?? 0}',
                                          style: AppText.headlineMd,
                                        ),
                                        Text('Days Left', style: AppText.labelCaps),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: AppSpacing.stackLg),
                            Text('About', style: AppText.titleSm),
                            const SizedBox(height: AppSpacing.stackSm),
                            Text(
                              campaign.description,
                              style: AppText.bodyBase,
                            ),
                            
                            const SizedBox(height: AppSpacing.stackLg),
                            Text('Where the money goes', style: AppText.titleSm),
                            const SizedBox(height: AppSpacing.stackSm),
                            ...allocations.map((alloc) => Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.stackSm),
                              child: Container(
                                padding: const EdgeInsets.all(AppSpacing.stackMd),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerLowest,
                                  border: Border.all(color: AppColors.cardBorder),
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(alloc.purpose, style: AppText.bodyBase),
                                    Text(
                                      'RM ${(alloc.amountSen / 100).toStringAsFixed(0)}',
                                      style: AppText.bodyBase.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Sticky CTA
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      padding: AppSpacing.pagePadding.copyWith(
                        bottom: AppSpacing.containerPadding + MediaQuery.of(context).padding.bottom,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.8),
                        border: Border(top: BorderSide(color: AppColors.cardBorder)),
                      ),
                      child: ElevatedButton(
                        onPressed: (campaign.status == CampaignStatus.active &&
                                campaign.currentAmountSen < campaign.goalAmountSen)
                            ? () => context.push('/donate/${campaign.id}')
                            : null,
                        child: Text(
                          campaign.status == CampaignStatus.completed ||
                                  campaign.currentAmountSen >= campaign.goalAmountSen
                              ? 'Campaign Completed'
                              : campaign.status == CampaignStatus.archived
                                  ? 'Campaign Archived'
                                  : 'Donate Now',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

