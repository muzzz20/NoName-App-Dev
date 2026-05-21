import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../models/campaign.dart';
import '../services/campaigns_service.dart';
import '../services/payment_service.dart';

/// Donation amount entry → Stripe Checkout redirect (NAD-21/26).
///
/// Card data is NEVER entered here — tapping "Proceed to Payment"
/// redirects to Stripe's hosted checkout. The donation doc is written
/// server-side by the `stripeWebhook` Cloud Function once Stripe
/// confirms the charge; the receipt screen then streams it by session.
class DonationFlowScreen extends StatefulWidget {
  final String campaignId;

  const DonationFlowScreen({super.key, required this.campaignId});

  @override
  State<DonationFlowScreen> createState() => _DonationFlowScreenState();
}

class _DonationFlowScreenState extends State<DonationFlowScreen> {
  double? _selectedAmount;
  final TextEditingController _customAmountController = TextEditingController();
  bool _isLoading = false;

  final _campaignsService = CampaignsService();
  final _paymentService = PaymentService();
  late Future<Campaign?> _campaignFuture;

  final List<double> _presets = [10, 20, 50];

  @override
  void initState() {
    super.initState();
    _campaignFuture = _campaignsService.getCampaign(widget.campaignId);
  }

  @override
  void dispose() {
    _customAmountController.dispose();
    super.dispose();
  }

  void _handlePresetSelected(double amount) {
    setState(() {
      _selectedAmount = amount;
      _customAmountController.clear();
    });
  }

  Future<void> _proceedToPayment() async {
    final amountText = _customAmountController.text;
    final amount =
        amountText.isNotEmpty ? double.tryParse(amountText) : _selectedAmount;

    if (amount == null || amount < 5) {
      _showError('Please select or enter an amount of at least RM 5.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final donorName = user?.displayName ?? 'Anonymous Supporter';

      // Redirects the browser to Stripe's hosted checkout. On web the
      // current tab navigates away; control returns via the success_url
      // (/receipt?session_id=...). The donation is written by the webhook.
      await _paymentService.startCheckout(
        amountSen: (amount * 100).round(),
        campaignId: widget.campaignId,
        donorName: donorName,
        origin: Uri.base.origin,
      );
      // On web we've navigated away by now; this line only runs on
      // platforms where the launch returns control. Keep the spinner
      // until the user comes back.
    } on PaymentFailure catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError('Something went wrong starting payment. Please try again.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Donate'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/campaigns'),
        ),
      ),
      body: FutureBuilder<Campaign?>(
        future: _campaignFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 64, color: AppColors.error),
                  const SizedBox(height: AppSpacing.stackMd),
                  Text('Campaign not found.', style: AppText.bodyBase),
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

          final campaign = snapshot.data!;

          final isNotDonatable = campaign.status == CampaignStatus.completed ||
              campaign.status == CampaignStatus.archived ||
              campaign.currentAmountSen >= campaign.goalAmountSen;

          if (isNotDonatable) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.stackLg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_outline,
                        size: 64, color: AppColors.primary),
                    const SizedBox(height: AppSpacing.stackMd),
                    Text(
                      'This campaign has been completed!',
                      style: AppText.titleSm,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.stackSm),
                    Text(
                      'Thank you for your generosity, but we are no longer '
                      'accepting donations because the goal has been met.',
                      style:
                          AppText.bodyBase.copyWith(color: AppColors.secondary),
                      textAlign: TextAlign.center,
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
              ),
            );
          }

          return Stack(
            children: [
              SafeArea(
                child: SingleChildScrollView(
                  padding: AppSpacing.pagePadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Campaign summary
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            child: Image.network(
                              campaign.imageUrl ?? '',
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                width: 60,
                                height: 60,
                                color: AppColors.surfaceVariant,
                                child: const Icon(Icons.pets,
                                    size: 24, color: AppColors.outline),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.stackMd),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('You are donating to:',
                                    style: AppText.labelCaps),
                                Text(campaign.title,
                                    style: AppText.titleSm,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.stackLg),
                      const Divider(),
                      const SizedBox(height: AppSpacing.stackLg),

                      Text('Select Amount', style: AppText.titleSm),
                      const SizedBox(height: AppSpacing.stackMd),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: _presets.map((amount) {
                          final isSelected = _selectedAmount == amount &&
                              _customAmountController.text.isEmpty;
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: amount != _presets.last
                                    ? AppSpacing.stackSm
                                    : 0,
                              ),
                              child: InkWell(
                                onTap: () => _handlePresetSelected(amount),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: AppSpacing.stackMd),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primaryContainer
                                        : AppColors.surfaceContainerLowest,
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.md),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primaryContainer
                                          : AppColors.cardBorder,
                                      width: 1.5,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'RM ${amount.toInt()}',
                                    style: AppText.bodyBase.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? AppColors.onPrimaryContainer
                                          : AppColors.onSurface,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppSpacing.stackMd),
                      TextField(
                        controller: _customAmountController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          hintText: 'Custom Amount (RM, min 5)',
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        onChanged: (val) {
                          if (val.isNotEmpty) {
                            setState(() => _selectedAmount = null);
                          }
                        },
                      ),

                      const SizedBox(height: AppSpacing.stackLg),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.stackMd),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryContainer,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.lock_outline,
                                size: 20, color: AppColors.primary),
                            const SizedBox(width: AppSpacing.stackSm),
                            Expanded(
                              child: Text(
                                "You'll be redirected to Stripe's secure "
                                'checkout to complete payment. Test card: '
                                '4242 4242 4242 4242.',
                                style: AppText.bodySm
                                    .copyWith(color: AppColors.secondary),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.stackXl),
                      ElevatedButton.icon(
                        onPressed: _proceedToPayment,
                        icon: const Icon(Icons.lock),
                        label: const Text('Proceed to Secure Payment'),
                      ),
                    ],
                  ),
                ),
              ),
              if (_isLoading)
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      color: AppColors.surface.withValues(alpha: 0.5),
                      child: const Center(child: CircularProgressIndicator()),
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
