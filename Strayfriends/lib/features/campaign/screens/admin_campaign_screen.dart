import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../services/campaign_service.dart';
import '../models/campaign_model.dart';
import '../models/campaign_failure.dart';
import '../widgets/campaign_management_card.dart';

class AdminCampaignScreen extends StatefulWidget {
  /// Admin-only view to list and manage campaigns.
  const AdminCampaignScreen({super.key});

  @override
  State<AdminCampaignScreen> createState() => _AdminCampaignScreenState();
}

class _AdminCampaignScreenState extends State<AdminCampaignScreen> {
  final bool isAdmin = true; // STUB: replace with NAD-22 role check when merged
  final _service = CampaignService();
  List<CampaignModel> _campaigns = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCampaigns();
  }

  Future<void> _loadCampaigns() async {
    try {
      final data = await _service.fetchAdminCampaigns();
      if (mounted) {
        setState(() {
          _campaigns = data;
          _isLoading = false;
        });
      }
    } on CampaignFailure catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _confirmEndEarly(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End Campaign?'),
        content: const Text('Are you sure you want to close this campaign early?'),
        actions: [
          TextButton(onPressed: () => ctx.pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => ctx.pop(true),
            child: const Text('End Now', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _service.endCampaign(id);
      _loadCampaigns();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isAdmin) {
      return const Scaffold(body: Center(child: Text('Access Denied')));
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Manage Campaigns', style: TextStyle(color: AppColors.onSurface)),
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _campaigns.length,
              itemBuilder: (ctx, i) => CampaignManagementCard(
                campaign: _campaigns[i],
                onEdit: () {
                  // context.push passes the campaign id to the form for editing
                  context.push(AppRoutes.campaignNew, extra: _campaigns[i]);
                },
                onEndEarly: () => _confirmEndEarly(_campaigns[i].id),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => context.push(AppRoutes.campaignNew),
        child: const Icon(Icons.add, color: AppColors.onPrimary),
      ),
    );
  }
}
