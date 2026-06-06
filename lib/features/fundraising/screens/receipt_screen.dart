import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
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

  // Safety net: the webhook usually lands in 1-2s. If it hasn't after this,
  // surface a way out instead of spinning forever.
  bool _slow = false;
  Timer? _slowTimer;

  @override
  void initState() {
    super.initState();
    if (widget.sessionId.isNotEmpty) {
      _slowTimer = Timer(const Duration(seconds: 12), () {
        if (mounted) setState(() => _slow = true);
      });
    }
  }

  @override
  void dispose() {
    _slowTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.sessionId.isEmpty) {
      return _Shell(child: _noReceipt(context));
    }

    return _Shell(
      // Returning from Stripe is a full page reload on web; wait for Firebase
      // Auth to restore before querying — the donations read rule needs the
      // signed-in uid (we filter by donorId to satisfy it).
      child: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnap) {
          if (authSnap.connectionState == ConnectionState.waiting) {
            return _confirming();
          }
          final uid = authSnap.data?.uid;
          if (uid == null) {
            return _signInToView(context);
          }
          return StreamBuilder<Donation?>(
            stream: _donationsService.watchDonationBySession(
              sessionId: widget.sessionId,
              donorId: uid,
            ),
            builder: (context, snap) {
              if (snap.hasError) {
                return _error(context);
              }
              final donation = snap.data;
              if (donation == null) {
                return _confirming();
              }
              return _receipt(context, donation);
            },
          );
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
        if (_slow) ...[
          const SizedBox(height: AppSpacing.stackLg),
          Text(
            'Taking longer than expected. Your payment went through — the '
            'receipt will appear under My Donations once recorded.',
            style: AppText.bodySm.copyWith(color: AppColors.outline),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.stackMd),
          OutlinedButton(
            onPressed: () => context.go('/my-donations'),
            child: const Text('Go to My Donations'),
          ),
        ],
      ],
    );
  }

  Widget _signInToView(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.lock_outline, size: 64, color: AppColors.outline),
        const SizedBox(height: AppSpacing.stackMd),
        Text('Sign in to view your receipt',
            style: AppText.titleSm, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.stackSm),
        Text(
          'Your payment was processed. Sign in with the account you donated '
          'from to see the receipt.',
          style: AppText.bodySm.copyWith(color: AppColors.secondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.stackLg),
        FilledButton(
          onPressed: () => context.go('/login'),
          child: const Text('Sign In'),
        ),
      ],
    );
  }

  Widget _error(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.cloud_off_outlined, size: 56, color: AppColors.outline),
        const SizedBox(height: AppSpacing.stackMd),
        Text("Couldn't load your receipt",
            style: AppText.titleSm, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.stackSm),
        Text(
          'Your payment went through — find it under My Donations.',
          style: AppText.bodySm.copyWith(color: AppColors.outline),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.stackLg),
        OutlinedButton(
          onPressed: () => context.go('/my-donations'),
          child: const Text('Go to My Donations'),
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
