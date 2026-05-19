import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../models/receipt_model.dart';
import '../widgets/receipt_detail_row.dart';

class DonationReceiptScreen extends StatelessWidget {
  final ReceiptModel receipt;

  /// Displays a read-only receipt passed via route arguments.
  const DonationReceiptScreen({super.key, required this.receipt});

  // DEPENDENCY NEEDED: share_plus — reason: Native sharing capability for AC3.
  // DEPENDENCY NEEDED: pdf — reason: PDF generation for AC2.
  void _exportAsPdf(BuildContext context) {
    // STUB: PDF export logic will go here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF Export Stubbed')),
    );
  }

  void _shareReceipt(BuildContext context) {
    // STUB: Native share logic will go here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Native Share Stubbed')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final amountFormatted = 'RM ${receipt.amount.toStringAsFixed(2)}';
    final dateFormatted = '${receipt.date.day}/${receipt.date.month}/${receipt.date.year}';

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Donation Receipt', style: TextStyle(color: AppColors.onSurface)),
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: AppColors.primary),
            onPressed: () => _exportAsPdf(context),
          ),
          IconButton(
            icon: const Icon(Icons.share, color: AppColors.primary),
            onPressed: () => _shareReceipt(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.check_circle, color: AppColors.primary, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Thank you for your donation!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 32),
              ReceiptDetailRow(label: 'Amount', value: amountFormatted, isHighlight: true),
              const Divider(color: AppColors.outlineVariant),
              ReceiptDetailRow(label: 'Donor Name', value: receipt.donorName),
              ReceiptDetailRow(label: 'Campaign', value: receipt.campaignName),
              ReceiptDetailRow(label: 'Date', value: dateFormatted),
              ReceiptDetailRow(label: 'Donation ID', value: receipt.donationId),
              ReceiptDetailRow(label: 'Transaction ID', value: receipt.transactionId),
            ],
          ),
        ),
      ),
    );
  }
}
