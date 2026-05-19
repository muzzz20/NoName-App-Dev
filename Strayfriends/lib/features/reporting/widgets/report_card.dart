import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../models/cat_report.dart';
import 'condition_badge.dart';

/// Reusable list-tile card for a [CatReport]. Used by Feed (NAD-12) and
/// My Reports (NAD-14).
class ReportCard extends StatelessWidget {
  final CatReport report;
  final VoidCallback onTap;
  final bool showStatusBadge;

  const ReportCard({
    super.key,
    required this.report,
    required this.onTap,
    this.showStatusBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: AppRadius.cardRadius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.stackSm + 4),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: AppRadius.cardRadius,
                child: SizedBox(
                  width: 76,
                  height: 76,
                  child: report.photoUrl.isEmpty
                      ? _PhotoFallback()
                      : Image.network(
                          report.photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _PhotoFallback(),
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              color: AppColors.surfaceContainer,
                              alignment: Alignment.center,
                              child: const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(width: AppSpacing.stackMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            report.locationLabel?.isNotEmpty == true
                                ? report.locationLabel!
                                : _formatLatLng(report),
                            style: AppText.bodyBase.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.stackSm),
                        ConditionBadge(condition: report.condition),
                      ],
                    ),
                    if (report.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        report.description,
                        style: AppText.bodySm.copyWith(
                          color: AppColors.onSurface
                              .withValues(alpha: 0.75),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 12,
                          color: AppColors.outline,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _timeAgo(report.createdAt),
                          style: AppText.labelCaps
                              .copyWith(color: AppColors.outline),
                        ),
                        if (showStatusBadge) ...[
                          const SizedBox(width: AppSpacing.stackMd),
                          _StatusPill(status: report.status),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatLatLng(CatReport r) =>
      '${r.location.latitude.toStringAsFixed(4)}, '
      '${r.location.longitude.toStringAsFixed(4)}';
}

class _StatusPill extends StatelessWidget {
  final ReportStatus status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      ReportStatus.pending => (
          AppColors.surfaceContainerHigh,
          AppColors.onSurfaceVariant,
        ),
      ReportStatus.inProgress => (
          AppColors.primaryContainer,
          AppColors.onPrimary,
        ),
      ReportStatus.resolved => (
          AppColors.tertiaryContainer,
          AppColors.onTertiaryContainer,
        ),
      ReportStatus.rejected => (
          AppColors.errorContainer,
          AppColors.onErrorContainer,
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.pillRadius),
      child: Text(
        status.label.toUpperCase(),
        style: AppText.labelCaps.copyWith(color: fg, fontSize: 10),
      ),
    );
  }
}

class _PhotoFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceContainer,
      alignment: Alignment.center,
      child: const Icon(
        Icons.pets_outlined,
        color: AppColors.outline,
      ),
    );
  }
}

String _timeAgo(DateTime when) {
  final diff = DateTime.now().toUtc().difference(when.toUtc());
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
  if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
  return '${(diff.inDays / 365).floor()}y ago';
}
