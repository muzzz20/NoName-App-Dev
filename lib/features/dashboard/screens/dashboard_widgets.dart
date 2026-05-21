import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../services/dashboard_service.dart';

/// A single KPI tile's data.
class KpiItem {
  final String label;
  final String value;
  final IconData icon;
  const KpiItem(this.label, this.value, this.icon);
}

/// Responsive 2-column grid of KPI cards.
class KpiGrid extends StatelessWidget {
  final List<KpiItem> items;
  const KpiGrid({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.stackMd,
      crossAxisSpacing: AppSpacing.stackMd,
      childAspectRatio: 1.7,
      children: items.map((i) => _KpiCard(item: i)).toList(),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final KpiItem item;
  const _KpiCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(item.icon, color: AppColors.primary, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.value,
                  style: AppText.titleSm.copyWith(color: AppColors.primary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Text(item.label,
                  style:
                      AppText.bodySm.copyWith(color: AppColors.secondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ],
      ),
    );
  }
}

/// Lightweight 30-day donation bar chart (no charting dependency).
/// Each bar is a day; height scales to the max day in the window.
class DonationSparkline extends StatelessWidget {
  final List<DailyDonation> data;
  const DonationSparkline({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Text('No donation data yet.',
          style: AppText.bodyBase.copyWith(color: AppColors.secondary));
    }
    final maxSen = data.map((d) => d.totalSen).fold<int>(0, (a, b) => a > b ? a : b);
    final totalSen = data.fold<int>(0, (a, b) => a + b.totalSen);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 100,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: data.map((d) {
              final frac = maxSen == 0 ? 0.0 : d.totalSen / maxSen;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: Container(
                    height: (frac * 90) + 2,
                    decoration: BoxDecoration(
                      color: d.totalSen == 0
                          ? AppColors.surfaceVariant
                          : AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '30-day total: RM ${(totalSen / 100).toStringAsFixed(2)}',
          style: AppText.bodySm.copyWith(color: AppColors.secondary),
        ),
      ],
    );
  }
}
