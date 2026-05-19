import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class AmountChipSelector extends StatelessWidget {
  final double selectedAmount;
  final ValueChanged<double> onAmountChanged;
  final bool isCustom;
  final VoidCallback onCustomSelected;

  /// A selector for preset amounts and toggling custom inputs.
  const AmountChipSelector({
    super.key,
    required this.selectedAmount,
    required this.onAmountChanged,
    required this.isCustom,
    required this.onCustomSelected,
  });

  final List<double> presets = const [5, 10, 20, 50, 100];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...presets.map((amount) {
          final isSelected = !isCustom && selectedAmount == amount;
          return ChoiceChip(
            label: Text('RM ${amount.toInt()}'),
            selected: isSelected,
            selectedColor: AppColors.primaryContainer,
            labelStyle: TextStyle(
              color: isSelected ? AppColors.onPrimaryContainer : AppColors.onSurface,
            ),
            onSelected: (_) {
              onAmountChanged(amount);
            },
          );
        }),
        ChoiceChip(
          label: const Text('Custom'),
          selected: isCustom,
          selectedColor: AppColors.primaryContainer,
          labelStyle: TextStyle(
            color: isCustom ? AppColors.onPrimaryContainer : AppColors.onSurface,
          ),
          onSelected: (_) => onCustomSelected(),
        ),
      ],
    );
  }
}
