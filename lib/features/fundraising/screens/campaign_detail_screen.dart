import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/sign_in_prompt.dart';
import '../services/campaigns_service.dart';
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
  final _campaignsService = CampaignsService();
  late Future<TransparencyReport> _reportFuture;
  final _authService = AuthService();
  final Map<String, String> _creatorNames = {};

  String? _role;
  bool get _isAdmin => _role == 'admin' || _role == 'ngo';

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
    _loadRole();
  }

  void _loadReport() {
    _reportFuture = _transparencyService.getReport(campaignId: widget.campaignId);
  }

  Future<void> _loadRole() async {
    if (FirebaseAuth.instance.currentUser == null) return;
    try {
      final p = await _authService.loadProfile();
      if (mounted) setState(() => _role = p?.role);
    } catch (_) {/* role stays null → no admin controls */}
  }

  // UC-16: admin/NGO closes an active campaign (stops donations, marks
  // completed). Edit-in-place is intentionally not offered — mutating goal /
  // allocations after donations would break the transparency invariant.
  Future<void> _closeCampaign(Campaign campaign) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Close this campaign?'),
        content: const Text(
            'It will stop accepting donations and be marked completed. '
            'This cannot be undone from the app.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Close campaign')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _campaignsService.updateCampaign(
          campaignId: campaign.id, status: CampaignStatus.completed);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Campaign closed.')));
      setState(_loadReport);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Couldn't close the campaign. Please try again."),
        backgroundColor: AppColors.error,
      ));
    }
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
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go('/campaigns'),
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
                                      onPressed: () => context.canPop()
                                          ? context.pop()
                                          : context.go('/campaigns'), // BR-005 + BR-013 fix
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Admin/NGO: close an active campaign (UC-16).
                          if (_isAdmin &&
                              campaign.status == CampaignStatus.active)
                            SafeArea(
                              child: Align(
                                alignment: Alignment.topRight,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.all(AppSpacing.stackMd),
                                  child: ClipOval(
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                          sigmaX: 10, sigmaY: 10),
                                      child: Container(
                                        color: AppColors.surface
                                            .withValues(alpha: 0.6),
                                        child: IconButton(
                                          icon: const Icon(Icons.lock_outline),
                                          color: AppColors.onSurface,
                                          tooltip: 'Close campaign',
                                          onPressed: () =>
                                              _closeCampaign(campaign),
                                        ),
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
                                _StatusChip(campaign: campaign),
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
                                  'RM ${(campaign.currentAmountSen / 100).toStringAsFixed(2)}',
                                  style: AppText.titleSm.copyWith(color: AppColors.primary),
                                ),
                                Text(
                                  'RM ${(campaign.goalAmountSen / 100).toStringAsFixed(2)} Goal',
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
                                    child: Builder(
                                      builder: (_) {
                                        final completed = campaign.status ==
                                                CampaignStatus.completed ||
                                            campaign.isCompleted;
                                        final days = campaign.endsAt
                                            ?.difference(DateTime.now())
                                            .inDays;
                                        // A completed/funded campaign shows
                                        // "Done", not a stale countdown.
                                        final value = completed
                                            ? '✓'
                                            : (days != null && days >= 0)
                                                ? '$days'
                                                : '—';
                                        final label = completed
                                            ? 'Completed'
                                            : 'Days Left';
                                        return Column(
                                          children: [
                                            Text(value,
                                                style: AppText.headlineMd),
                                            Text(label,
                                                style: AppText.labelCaps),
                                          ],
                                        );
                                      },
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
                            const SizedBox(height: AppSpacing.stackXs),
                            Text(
                              'RM ${(report.totalAllocatedSen / 100).toStringAsFixed(2)} allocated '
                              'of RM ${(campaign.goalAmountSen / 100).toStringAsFixed(2)} goal',
                              style: AppText.bodySm
                                  .copyWith(color: AppColors.secondary),
                            ),
                            const SizedBox(height: AppSpacing.stackMd),
                            if (allocations.isEmpty)
                              Container(
                                padding:
                                    const EdgeInsets.all(AppSpacing.stackMd),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerLowest,
                                  border:
                                      Border.all(color: AppColors.cardBorder),
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.md),
                                ),
                                child: Text(
                                  'No spending allocations recorded yet.',
                                  style: AppText.bodySm
                                      .copyWith(color: AppColors.outline),
                                ),
                              )
                            else
                              // Each allocation as a labelled proportion bar
                              // (share of the campaign goal) — turns the spend
                              // breakdown into a visual transparency story.
                              ...allocations.map((alloc) {
                                final frac = campaign.goalAmountSen > 0
                                    ? (alloc.amountSen /
                                            campaign.goalAmountSen)
                                        .clamp(0.0, 1.0)
                                    : 0.0;
                                return Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: AppSpacing.stackMd),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(alloc.purpose,
                                                style: AppText.bodyBase),
                                          ),
                                          const SizedBox(
                                              width: AppSpacing.stackSm),
                                          Text(
                                            'RM ${(alloc.amountSen / 100).toStringAsFixed(2)}',
                                            style: AppText.bodyBase.copyWith(
                                                fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                            AppRadius.full),
                                        child: LinearProgressIndicator(
                                          value: frac,
                                          minHeight: 8,
                                          backgroundColor:
                                              AppColors.surfaceVariant,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            if (report.unallocatedSen > 0) ...[
                              const SizedBox(height: AppSpacing.stackSm),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Unallocated',
                                      style: AppText.bodySm.copyWith(
                                          color: AppColors.secondary)),
                                  Text(
                                    'RM ${(report.unallocatedSen / 100).toStringAsFixed(2)}',
                                    style: AppText.bodySm.copyWith(
                                        color: AppColors.secondary,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ],
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
                            // Donation is registered-only (UC-12): a visitor is
                            // prompted to sign in instead of hitting the flow.
                            ? () => FirebaseAuth.instance.currentUser != null
                                ? context.push('/donate/${campaign.id}')
                                : showSignInPrompt(context, 'donate')
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

/// Status pill that colours by lifecycle: active = maroon, completed/funded
/// = success-tinted, archived = muted.
class _StatusChip extends StatelessWidget {
  final Campaign campaign;
  const _StatusChip({required this.campaign});

  @override
  Widget build(BuildContext context) {
    final completed =
        campaign.status == CampaignStatus.completed || campaign.isCompleted;
    final (bg, fg) = completed
        ? (AppColors.tertiaryContainer, AppColors.onTertiaryContainer)
        : campaign.status == CampaignStatus.archived
            ? (AppColors.surfaceVariant, AppColors.onSurfaceVariant)
            : (AppColors.primaryContainer, AppColors.onPrimaryContainer);
    final label =
        completed ? 'Completed' : campaign.status.label;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.stackMd,
        vertical: AppSpacing.stackXs,
      ),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.pillRadius),
      child: Text(
        label.toUpperCase(),
        style: AppText.labelCaps.copyWith(color: fg),
      ),
    );
  }
}

