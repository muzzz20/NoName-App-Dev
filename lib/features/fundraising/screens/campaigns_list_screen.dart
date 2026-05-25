import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../auth/models/user_profile.dart';
import '../../auth/services/auth_service.dart';
import '../models/campaign.dart';
import '../services/campaigns_service.dart';
import '../widgets/campaign_card.dart';

enum _Sort {
  endingSoon('Ending soon'),
  mostFunded('Most funded'),
  newest('Newest');

  const _Sort(this.label);
  final String label;
}

class CampaignsListScreen extends StatefulWidget {
  const CampaignsListScreen({super.key});

  @override
  State<CampaignsListScreen> createState() => _CampaignsListScreenState();
}

class _CampaignsListScreenState extends State<CampaignsListScreen> {
  final _campaignsService = CampaignsService();
  final _authService = AuthService();

  String _filter = 'All'; // All, Active, Completed
  _Sort _sort = _Sort.newest;
  UserProfile? _profile;

  bool get _isSignedIn => FirebaseAuth.instance.currentUser != null;
  bool get _isAdmin => _profile?.role == 'admin' || _profile?.role == 'ngo';

  @override
  void initState() {
    super.initState();
    if (_isSignedIn) {
      _authService.loadProfile().then((p) {
        if (mounted) setState(() => _profile = p);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Campaign>>(
        stream: _campaignsService.watchAllCampaigns(),
        builder: (context, snapshot) {
          final all = snapshot.data ?? const <Campaign>[];
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                title: Text('Fundraising', style: AppText.titleSm),
                pinned: true,
                // Explicit back: this screen can be reached as a fresh root
                // (e.g. receipt → "Back to Campaigns" via go), where there's
                // nothing to pop — fall back to home so the user is never stuck.
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.canPop()
                      ? context.pop()
                      : context.go(AppRoutes.home),
                ),
                flexibleSpace: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      color: AppColors.surface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                actions: [
                  PopupMenuButton<_Sort>(
                    icon: const Icon(Icons.sort),
                    tooltip: 'Sort',
                    initialValue: _sort,
                    onSelected: (s) => setState(() => _sort = s),
                    itemBuilder: (_) => _Sort.values
                        .map((s) => PopupMenuItem(
                              value: s,
                              child: Text(s.label),
                            ))
                        .toList(),
                  ),
                  // History (my donations) — registered users only.
                  if (_isSignedIn)
                    IconButton(
                      tooltip: 'My donations',
                      icon: const Icon(Icons.history),
                      onPressed: () => context.push(AppRoutes.myDonations),
                    ),
                  // Create campaign — admin / NGO only (UC-15).
                  if (_isAdmin)
                    IconButton(
                      key: const ValueKey('btnNewCampaign'),
                      tooltip: 'New campaign',
                      icon: const Icon(Icons.add_box_outlined),
                      onPressed: () => context.push(AppRoutes.adminCampaign),
                    ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(60),
                  child: Padding(
                    padding: AppSpacing.horizontalPagePadding
                        .copyWith(bottom: AppSpacing.stackMd),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['All', 'Active', 'Completed'].map((filter) {
                          final isSelected = _filter == filter;
                          return Padding(
                            padding:
                                const EdgeInsets.only(right: AppSpacing.stackSm),
                            child: ChoiceChip(
                              label: Text(filter),
                              selected: isSelected,
                              showCheckmark: false,
                              onSelected: (selected) {
                                if (selected) setState(() => _filter = filter);
                              },
                              selectedColor: AppColors.primaryContainer,
                              labelStyle: AppText.labelCaps.copyWith(
                                color: isSelected
                                    ? AppColors.onPrimary
                                    : AppColors.onSurfaceVariant,
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
              _buildContent(context, snapshot, all),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AsyncSnapshot<List<Campaign>> snapshot,
    List<Campaign> all,
  ) {
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off_outlined,
                    size: 56, color: AppColors.outline),
                const SizedBox(height: AppSpacing.stackMd),
                Text("Couldn't load campaigns",
                    style: AppText.titleSm, textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.stackSm),
                Text('Check your connection and try again.',
                    style:
                        AppText.bodySm.copyWith(color: AppColors.outline),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      );
    }

    final filtered = all.where((c) {
      if (_filter == 'All') return true;
      return c.status.name.toLowerCase() == _filter.toLowerCase();
    }).toList()
      ..sort(_compare);

    if (filtered.isEmpty) {
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
      padding: AppSpacing.pagePadding.copyWith(top: AppSpacing.stackSm),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final campaign = filtered[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.stackMd),
              child: CampaignCard(
                campaign: campaign,
                onTap: () => context.push('/campaign/${campaign.id}'),
              ),
            );
          },
          childCount: filtered.length,
        ),
      ),
    );
  }

  int _compare(Campaign a, Campaign b) {
    switch (_sort) {
      case _Sort.mostFunded:
        return b.progress.compareTo(a.progress);
      case _Sort.endingSoon:
        // Active campaigns with the nearest end date first; nulls last.
        final ae = a.endsAt, be = b.endsAt;
        if (ae == null && be == null) return 0;
        if (ae == null) return 1;
        if (be == null) return -1;
        return ae.compareTo(be);
      case _Sort.newest:
        return b.createdAt.compareTo(a.createdAt);
    }
  }
}
