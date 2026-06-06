import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../models/cat_report.dart';

/// Pill-shaped chip showing a [CatCondition].
///
/// Color choice follows DESIGN.md semantic palette:
/// - Healthy → success-leaning (we use tertiaryContainer for neutral warm)
/// - Injured → error / emergency red
/// - Sick    → primaryContainer (UTM Maroon variant)
class ConditionBadge extends StatelessWidget {
  final CatCondition condition;

  /// Compact variant for dense surfaces (e.g. overlaid on a thumbnail in
  /// [ReportCard]): tighter padding and smaller caps.
  final bool compact;

  const ConditionBadge({
    super.key,
    required this.condition,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _palette(condition);
    return Container(
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 3)
          : const EdgeInsets.symmetric(
              horizontal: AppSpacing.stackSm + 4,
              vertical: 4,
            ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.pillRadius,
      ),
      child: Text(
        condition.label.toUpperCase(),
        style: compact
            ? AppText.labelCaps.copyWith(color: fg, fontSize: 10)
            : AppText.labelCaps.copyWith(color: fg),
      ),
    );
  }

  (Color, Color) _palette(CatCondition c) {
    switch (c) {
      case CatCondition.healthy:
        return (AppColors.tertiaryContainer, AppColors.onTertiaryContainer);
      case CatCondition.injured:
        return (AppColors.errorContainer, AppColors.onErrorContainer);
      case CatCondition.sick:
        return (AppColors.primaryContainer, AppColors.onPrimary);
    }
  }
}
