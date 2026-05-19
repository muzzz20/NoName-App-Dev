import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class ReceiptDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;

  /// Reusable row widget for receipt key-value pairs.
  const ReceiptDetailRow({
    super.key,
    required this.label,
    required this.value,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isHighlight ? AppColors.primary : AppColors.onSurface,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
              fontSize: isHighlight ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
