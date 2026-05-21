import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../models/campaign.dart';
import '../models/donation.dart';
import '../services/campaigns_service.dart';
import '../services/donations_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DonationFlowScreen extends StatefulWidget {
  final String campaignId;

  const DonationFlowScreen({super.key, required this.campaignId});

  @override
  State<DonationFlowScreen> createState() => _DonationFlowScreenState();
}

class _DonationFlowScreenState extends State<DonationFlowScreen> {
  final _formKey = GlobalKey<FormState>();
  double? _selectedAmount;
  final TextEditingController _customAmountController = TextEditingController();
  bool _isLoading = false;

  final _campaignsService = CampaignsService();
  final _donationsService = DonationsService();
  late Future<Campaign?> _campaignFuture;
  Campaign? _campaign;

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

  /// Map a PaymentFailureCode storageKey to a user-friendly message
  /// (BR-011 — was showing the raw enum name in the snackbar).
  String _friendlyFailure(String? code) {
    switch (code) {
      case 'cardDeclined':
        return 'Your card was declined. Try a different payment method.';
      case 'insufficientFunds':
        return 'Insufficient funds. Reduce the amount or try another card.';
      case 'expiredCard':
        return 'Your card has expired. Please update your payment method.';
      case 'networkError':
        return 'Network error during payment. Check your connection and retry.';
      default:
        return 'Donation failed. Please try again.';
    }
  }

  void _submit() async {
    final amountText = _customAmountController.text;
    final amount = amountText.isNotEmpty ? double.tryParse(amountText) : _selectedAmount;

    if (amount == null || amount < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select or enter an amount of at least RM 5.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      final donorId = user?.uid ?? 'sim_user_123';
      final donorName = user?.displayName ?? 'Anonymous Supporter';
      
      final donation = await _donationsService.donate(
        donorId: donorId,
        campaignId: widget.campaignId,
        amountSen: (amount * 100).toInt(),
        donorName: donorName,
      );
      
      if (!mounted) return;
      setState(() => _isLoading = false);
      
      if (donation.status == DonationStatus.success) {
        context.pushReplacement('/receipt', extra: {
          'campaignName': _campaign?.title ?? 'Campaign',
          'amount': amount,
          'transactionId': donation.transactionId ?? 'N/A',
          'date': donation.createdAt,
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_friendlyFailure(donation.failureCode)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
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
                  const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: AppSpacing.stackMd),
                  Text('Campaign not found.', style: AppText.bodyBase),
                  const SizedBox(height: AppSpacing.stackLg),
                  ElevatedButton(
                    onPressed: () =>
              context.canPop() ? context.pop() : context.go('/campaigns'),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          final campaign = snapshot.data!;
          _campaign = campaign;

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
                    const Icon(Icons.check_circle_outline, size: 64, color: AppColors.primary),
                    const SizedBox(height: AppSpacing.stackMd),
                    Text(
                      'This campaign has been completed!',
                      style: AppText.titleSm,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.stackSm),
                    Text(
                      'Thank you for your generosity, but we are no longer accepting donations for this campaign because the goal has been fully met.',
                      style: AppText.bodyBase.copyWith(color: AppColors.secondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.stackLg),
                    ElevatedButton(
                      onPressed: () =>
              context.canPop() ? context.pop() : context.go('/campaigns'),
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
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: AppSpacing.pagePadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Campaign Summary
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              child: Image.network(
                                campaign.imageUrl ?? '',
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 60,
                                  height: 60,
                                  color: AppColors.surfaceVariant,
                                  child: const Icon(Icons.pets, size: 24, color: AppColors.outline),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.stackMd),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('You are donating to:', style: AppText.labelCaps),
                                  Text(campaign.title, style: AppText.titleSm, maxLines: 2, overflow: TextOverflow.ellipsis),
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
                            final isSelected = _selectedAmount == amount && _customAmountController.text.isEmpty;
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: amount != _presets.last ? AppSpacing.stackSm : 0,
                                ),
                                child: InkWell(
                                  onTap: () => _handlePresetSelected(amount),
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.stackMd),
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppColors.primaryContainer : AppColors.surfaceContainerLowest,
                                      borderRadius: BorderRadius.circular(AppRadius.md),
                                      border: Border.all(
                                        color: isSelected ? AppColors.primaryContainer : AppColors.cardBorder,
                                        width: 1.5,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'RM ${amount.toInt()}',
                                      style: AppText.bodyBase.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: isSelected ? AppColors.onPrimaryContainer : AppColors.onSurface,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: AppSpacing.stackMd),
                        TextFormField(
                          controller: _customAmountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            hintText: 'Custom Amount (RM)',
                            prefixIcon: Icon(Icons.attach_money),
                          ),
                          onChanged: (val) {
                            if (val.isNotEmpty) {
                              setState(() => _selectedAmount = null);
                            }
                          },
                        ),
                        
                        const SizedBox(height: AppSpacing.stackLg),
                        Text('Payment Details', style: AppText.titleSm),
                        const SizedBox(height: AppSpacing.stackMd),
                        TextFormField(
                          decoration: const InputDecoration(
                            hintText: 'Card Number',
                            prefixIcon: Icon(Icons.credit_card),
                          ),
                          validator: (v) => v == null || v.length < 16 ? 'Invalid card number' : null,
                        ),
                        const SizedBox(height: AppSpacing.stackMd),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                decoration: const InputDecoration(hintText: 'MM/YY'),
                                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.stackMd),
                            Expanded(
                              child: TextFormField(
                                decoration: const InputDecoration(hintText: 'CVC'),
                                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: AppSpacing.stackXl),
                        ElevatedButton(
                          onPressed: _submit,
                          child: const Text('Confirm Payment'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_isLoading)
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      color: AppColors.surface.withValues(alpha: 0.5),
                      child: const Center(
                        child: CircularProgressIndicator(),
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
