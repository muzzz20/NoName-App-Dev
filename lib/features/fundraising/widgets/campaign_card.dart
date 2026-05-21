import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../models/campaign.dart';

/// Campaign card matching the Home "Featured campaign" visual language:
/// 16:7 image with a status pill, title, progress bar + % funded, a
/// whole-RM money line, and days-left. Used by the Browse Campaigns list so
/// it stays consistent with the featured card on Home. Tapping opens detail.
class CampaignCard extends StatelessWidget {
  final Campaign campaign;
  final VoidCallback onTap;

  const CampaignCard({super.key, required this.campaign, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = campaign;
    final pct = (c.progress * 100).round();
    final daysLeft = c.endsAt?.difference(DateTime.now()).inDays;
    final isCompleted = c.status == CampaignStatus.completed || c.isCompleted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Opacity(
        opacity: isCompleted ? 0.7 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 7,
                    child: Image.network(
                      c.imageUrl ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: AppColors.surfaceVariant,
                        child: const Icon(Icons.pets,
                            size: 36, color: AppColors.outline),
                      ),
                    ),
                  ),
                  Positioned(
                    top: AppSpacing.stackSm,
                    left: AppSpacing.stackSm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppColors.surfaceVariant
                            : AppColors.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        c.status.label.toUpperCase(),
                        style: AppText.labelCaps.copyWith(
                          color: isCompleted
                              ? AppColors.onSurfaceVariant
                              : Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.stackMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.title,
                        style: AppText.bodyBase
                            .copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: AppSpacing.stackSm),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: c.progress,
                              minHeight: 10,
                              backgroundColor: AppColors.surfaceVariant,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.stackSm),
                        Text('$pct% funded',
                            style: AppText.bodySm.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(_rmWhole(c.currentAmountSen),
                            style: AppText.bodyBase
                                .copyWith(fontWeight: FontWeight.w700)),
                        Text(' raised',
                            style: AppText.bodySm
                                .copyWith(color: AppColors.secondary)),
                        Text('  ·  of ${_rmWhole(c.goalAmountSen)} goal',
                            style: AppText.bodySm
                                .copyWith(color: AppColors.secondary)),
                      ],
                    ),
                    if (daysLeft != null && daysLeft >= 0) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.schedule,
                              size: 13, color: AppColors.outline),
                          const SizedBox(width: 4),
                          Text(
                              daysLeft == 0
                                  ? 'Ends today'
                                  : '$daysLeft day(s) left',
                              style: AppText.labelCaps
                                  .copyWith(color: AppColors.outline)),
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
    );
  }
}

// Whole-ringgit formatter (no `intl` dependency), mirroring the Home feed.
// e.g. 150000 sen -> 'RM 1,500'.
String _thousands(int n) {
  final digits = n.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  return n < 0 ? '-$buf' : buf.toString();
}

String _rmWhole(int sen) => 'RM ${_thousands(sen ~/ 100)}';
