import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../models/cat_report.dart';
import 'condition_badge.dart';
import 'status_badge.dart';

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
              SizedBox(
                width: 84,
                height: 84,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.md),
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
                    Positioned(
                      left: 4,
                      bottom: 4,
                      child: ConditionBadge(
                        condition: report.condition,
                        compact: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.stackMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      report.locationLabel?.isNotEmpty == true
                          ? report.locationLabel!
                          : _formatLatLng(report),
                      style: AppText.bodyBase.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (report.description.isNotEmpty) ...[
                      const SizedBox(height: 3),
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
                    const SizedBox(height: 6),
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
                          StatusBadge(status: report.status, compact: true),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.stackSm),
              const Icon(
                Icons.chevron_right,
                color: AppColors.outline,
                size: 20,
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
