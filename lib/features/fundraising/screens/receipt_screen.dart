import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';

class ReceiptScreen extends StatelessWidget {
  final String campaignName;
  final double amount;
  final String transactionId;
  final DateTime date;

  const ReceiptScreen({
    super.key,
    required this.campaignName,
    required this.amount,
    required this.transactionId,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.pagePadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.check_circle,
                size: 80,
                color: Colors.green, // Success Green
              ),
              const SizedBox(height: AppSpacing.stackLg),
              Text(
                'Thank you!',
                textAlign: TextAlign.center,
                style: AppText.displayLg.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: AppSpacing.stackSm),
              Text(
                'Your donation helps make a difference.',
                textAlign: TextAlign.center,
                style: AppText.bodyBase.copyWith(color: AppColors.secondary),
              ),
              const SizedBox(height: AppSpacing.stackXl),
              
              // Receipt Card
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.onSurface.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.stackLg),
                      child: Column(
                        children: [
                          _buildReceiptRow('Amount', 'RM ${amount.toStringAsFixed(2)}', isHighlight: true),
                          const SizedBox(height: AppSpacing.stackMd),
                          _buildReceiptRow('Campaign', campaignName),
                          const SizedBox(height: AppSpacing.stackMd),
                          _buildReceiptRow('Date', '${date.day}/${date.month}/${date.year}'),
                          const SizedBox(height: AppSpacing.stackMd),
                          _buildReceiptRow('Transaction ID', transactionId),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppSpacing.stackXl),
              ElevatedButton(
                onPressed: () {
                  // Simulate share PDF
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sharing PDF...')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondaryContainer,
                  foregroundColor: AppColors.primary,
                ),
                child: const Text('Share Receipt'),
              ),
              const SizedBox(height: AppSpacing.stackMd),
              OutlinedButton(
                onPressed: () => context.go('/home'),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppText.bodyBase.copyWith(color: AppColors.secondary),
        ),
        const SizedBox(width: AppSpacing.stackMd),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: isHighlight
                ? AppText.titleSm.copyWith(color: AppColors.primary)
                : AppText.bodyBase.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
