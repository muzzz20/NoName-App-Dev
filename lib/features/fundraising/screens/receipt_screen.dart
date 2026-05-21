import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../models/campaign.dart';
import '../models/donation.dart';
import '../services/campaigns_service.dart';
import '../services/donations_service.dart';

/// Donation receipt (NAD-32). Reached after the Stripe Checkout redirect
/// at `/receipt?session_id=...`. Streams the donation the `stripeWebhook`
/// Cloud Function writes once Stripe confirms payment — so it shows a
/// "confirming" state for the ~1-2s until the webhook lands, then the
/// receipt.
class ReceiptScreen extends StatefulWidget {
  final String sessionId;

  const ReceiptScreen({super.key, required this.sessionId});

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  final _donationsService = DonationsService();
  final _campaignsService = CampaignsService();

  @override
  Widget build(BuildContext context) {
    if (widget.sessionId.isEmpty) {
      return _Shell(child: _noReceipt(context));
    }

    return _Shell(
      child: StreamBuilder<Donation?>(
        stream: _donationsService.watchDonationBySession(widget.sessionId),
        builder: (context, snap) {
          final donation = snap.data;
          if (donation == null) {
            return _confirming();
          }
          return _receipt(context, donation);
        },
      ),
    );
  }

  Widget _confirming() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: AppSpacing.stackLg),
        Text('Confirming your payment…',
            style: AppText.titleSm, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.stackSm),
        Text(
          'Hang tight — we are recording your donation.',
          style: AppText.bodyBase.copyWith(color: AppColors.secondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _noReceipt(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.receipt_long, size: 64, color: AppColors.outline),
        const SizedBox(height: AppSpacing.stackMd),
        Text('No receipt to show.', style: AppText.titleSm),
        const SizedBox(height: AppSpacing.stackLg),
        OutlinedButton(
          onPressed: () => context.go('/campaigns'),
          child: const Text('Back to Campaigns'),
        ),
      ],
    );
  }

  Widget _receipt(BuildContext context, Donation donation) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.check_circle, size: 80, color: Colors.green),
        const SizedBox(height: AppSpacing.stackLg),
        Text('Thank you!',
            textAlign: TextAlign.center,
            style: AppText.displayLg.copyWith(color: AppColors.primary)),
        const SizedBox(height: AppSpacing.stackSm),
        Text(
          'Your donation helps make a difference.',
          textAlign: TextAlign.center,
          style: AppText.bodyBase.copyWith(color: AppColors.secondary),
        ),
        const SizedBox(height: AppSpacing.stackXl),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.cardBorder),
          ),
          padding: const EdgeInsets.all(AppSpacing.stackLg),
          child: Column(
            children: [
              _row('Amount',
                  'RM ${(donation.amountSen / 100).toStringAsFixed(2)}',
                  highlight: true),
              const SizedBox(height: AppSpacing.stackMd),
              _CampaignNameRow(
                campaignId: donation.campaignId,
                service: _campaignsService,
              ),
              const SizedBox(height: AppSpacing.stackMd),
              _row('Date',
                  '${donation.createdAt.day}/${donation.createdAt.month}/${donation.createdAt.year}'),
              const SizedBox(height: AppSpacing.stackMd),
              _row('Transaction ID', donation.transactionId ?? '—'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.stackXl),
        OutlinedButton(
          onPressed: () => context.go('/campaigns'),
          child: const Text('Back to Campaigns'),
        ),
      ],
    );
  }

  Widget _row(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppText.bodyBase.copyWith(color: AppColors.secondary)),
        const SizedBox(width: AppSpacing.stackMd),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: highlight
                ? AppText.titleSm.copyWith(color: AppColors.primary)
                : AppText.bodyBase.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

/// Looks up the campaign title for the receipt (donation stores only id).
class _CampaignNameRow extends StatelessWidget {
  final String campaignId;
  final CampaignsService service;

  const _CampaignNameRow({required this.campaignId, required this.service});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Campaign?>(
      future: service.getCampaign(campaignId),
      builder: (context, snap) {
        final title = snap.data?.title ?? 'Campaign';
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Campaign',
                style: AppText.bodyBase.copyWith(color: AppColors.secondary)),
            const SizedBox(width: AppSpacing.stackMd),
            Expanded(
              child: Text(title,
                  textAlign: TextAlign.right,
                  style: AppText.bodyBase
                      .copyWith(fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }
}

class _Shell extends StatelessWidget {
  final Widget child;
  const _Shell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(padding: AppSpacing.pagePadding, child: child),
      ),
    );
  }
}
