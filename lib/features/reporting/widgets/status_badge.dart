import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../models/cat_report.dart';

/// Pill chip for a report's [ReportStatus]. Mirrors [ConditionBadge] so the
/// two read as a consistent badge pair. Shared by ReportCard, the All-Reports
/// list, and Report Detail.
class StatusBadge extends StatelessWidget {
  final ReportStatus status;

  /// Compact variant for dense surfaces (e.g. inline on a ReportCard).
  final bool compact;

  const StatusBadge({super.key, required this.status, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _palette(status);
    return Container(
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 2)
          : const EdgeInsets.symmetric(
              horizontal: AppSpacing.stackSm + 4, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.pillRadius),
      child: Text(
        status.label.toUpperCase(),
        style: compact
            ? AppText.labelCaps.copyWith(color: fg, fontSize: 10)
            : AppText.labelCaps.copyWith(color: fg),
      ),
    );
  }

  (Color, Color) _palette(ReportStatus s) {
    switch (s) {
      case ReportStatus.pending:
        return (AppColors.surfaceContainerHigh, AppColors.onSurfaceVariant);
      case ReportStatus.inProgress:
        return (AppColors.primaryContainer, AppColors.onPrimary);
      case ReportStatus.resolved:
        return (AppColors.tertiaryContainer, AppColors.onTertiaryContainer);
      case ReportStatus.rejected:
        return (AppColors.errorContainer, AppColors.onErrorContainer);
    }
  }
}
