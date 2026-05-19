import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';

/// Success confirmation after a report is created. Matches
/// `mockup-screens/report_success_screen.png`.
class ReportSuccessScreen extends StatelessWidget {
  final String? reportId;
  const ReportSuccessScreen({super.key, this.reportId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.pagePadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  size: 56,
                  color: AppColors.onPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.stackLg),
              Text(
                'Report Submitted!',
                style: AppText.headlineMd,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.stackSm),
              Text(
                'Volunteers in your area have been notified. '
                'Thank you for helping the strays of UTM.',
                style: AppText.bodySm.copyWith(color: AppColors.outline),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.stackXl),
              if (reportId != null) ...[
                OutlinedButton.icon(
                  onPressed: () {
                    // Replace success → home, then push detail so the
                    // back chevron on Detail returns to Feed (not Success).
                    context.go(AppRoutes.home);
                    context.push('${AppRoutes.reportDetail}/$reportId');
                  },
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('View Report'),
                ),
                const SizedBox(height: AppSpacing.stackMd),
              ],
              ElevatedButton.icon(
                onPressed: () => context.go(AppRoutes.home),
                icon: const Icon(Icons.home_outlined),
                label: const Text('Back to Feed'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
