import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../models/cat_report.dart';

/// Horizontal lifecycle stepper: Pending → In progress → Resolved, with the
/// current stage filled. A rejected status shows a dedicated banner instead.
/// Shared by Report Detail (sighting status) and Cat Profile (care status).
class StatusTimeline extends StatelessWidget {
  final ReportStatus status;
  const StatusTimeline({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    if (status == ReportStatus.rejected) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.stackMd),
        decoration: BoxDecoration(
          color: AppColors.errorContainer,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            const Icon(Icons.cancel_outlined,
                size: 18, color: AppColors.onErrorContainer),
            const SizedBox(width: AppSpacing.stackSm),
            Expanded(
              child: Text('Reviewed and marked rejected.',
                  style: AppText.bodySm
                      .copyWith(color: AppColors.onErrorContainer)),
            ),
          ],
        ),
      );
    }

    const steps = ['Pending', 'In progress', 'Resolved'];
    final current = switch (status) {
      ReportStatus.pending => 0,
      ReportStatus.inProgress => 1,
      ReportStatus.resolved => 2,
      ReportStatus.rejected => 0, // handled above
    };

    return Row(
      children: [
        for (var i = 0; i < steps.length; i++)
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                        child: _connector(active: i <= current, show: i != 0)),
                    _dot(reached: i <= current, done: i < current),
                    Expanded(
                        child: _connector(
                            active: i < current, show: i != steps.length - 1)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  steps[i],
                  style: AppText.labelCaps.copyWith(
                    color:
                        i <= current ? AppColors.onSurface : AppColors.outline,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _dot({required bool reached, required bool done}) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: reached ? AppColors.primary : AppColors.surfaceVariant,
        shape: BoxShape.circle,
      ),
      child:
          done ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
    );
  }

  Widget _connector({required bool active, required bool show}) {
    return Container(
      height: 2,
      color: show
          ? (active ? AppColors.primary : AppColors.outlineVariant)
          : Colors.transparent,
    );
  }
}
